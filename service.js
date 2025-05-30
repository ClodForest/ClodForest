#!/usr/bin/env node

/**
 * ClaudeLink Coordinator Service
 *
 * A NodeJS/Express service that provides the active portion of the ClaudeLink protocol.
 * Runs under ec2-user account, provides time services, repository access, and context coordination.
 *
 * Server Names:
 * - Service: claudelink-coordinator
 * - FreeBSD Repository Server: claudelink-vault
 */

const express = require('express');
const { execSync, spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 8080;
const FREEBSD_SERVER = process.env.FREEBSD_SERVER || 'claudelink-vault';
const REPO_BASE_PATH = process.env.REPO_PATH || '/public/file/0/git';
const GITHUB_REPO_PATH = '/public/file/0/git/claude-code-bundler';
const OAUTH_CLIENT_ID = process.env.OAUTH_CLIENT_ID || '';
const OAUTH_CLIENT_SECRET = process.env.OAUTH_CLIENT_SECRET || '';

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files for admin interface
app.use('/admin/static', express.static(path.join(__dirname, 'admin/static')));

// Static repository file serving (replaces publicfile functionality)
app.use('/static', express.static(GITHUB_REPO_PATH, {
  dotfiles: 'deny',
  index: false,
  redirect: false,
  setHeaders: function (res, path, stat) {
    // Set appropriate cache headers
    res.set('Cache-Control', 'public, max-age=3600'); // 1 hour cache
    res.set('X-Served-By', 'claudelink-coordinator');
  }
}));

// Repository file browser (HTML interface to static files)
app.get('/browse', (req, res) => {
  const requestedPath = req.query.path || '';
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>ClaudeLink Repository Browser</title>
      <style>
        body { font-family: system-ui, -apple-system, sans-serif; max-width: 1000px; margin: 0 auto; padding: 2rem; }
        .header { border-bottom: 2px solid #e1e5e9; padding-bottom: 1rem; margin-bottom: 2rem; }
        .path { background: #f8f9fa; padding: 1rem; border-radius: 0.5rem; font-family: Monaco, 'Courier New', monospace; }
        .file-list { list-style: none; padding: 0; }
        .file-item { padding: 0.5rem; border-bottom: 1px solid #e1e5e9; }
        .file-item:hover { background: #f8f9fa; }
        .file-link { text-decoration: none; color: #007bff; }
        .file-link:hover { text-decoration: underline; }
        .static-note { background: #d1ecf1; border: 1px solid #bee5eb; padding: 1rem; border-radius: 0.5rem; margin: 1rem 0; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>📁 ClaudeLink Repository Browser</h1>
        <p>Browse repository files served directly by the coordinator</p>
        <div class="path">Path: /${requestedPath}</div>
      </div>

      <div class="static-note">
        <strong>Note:</strong> Static files are served via <code>/static/*</code> endpoint.
        This replaces the publicfile functionality for simplified architecture.
      </div>

      <div>
        <p><a href="/api/repository/claude-code-bundler">📋 JSON API</a> |
           <a href="/admin?dev_admin=true">🛠️ Admin Interface</a> |
           <a href="/static/README.md">📄 Repository README</a></p>
      </div>

      <div id="file-browser">
        <p>🔄 Loading repository contents...</p>
        <script>
          fetch('/api/repository/claude-code-bundler?path=${encodeURIComponent(requestedPath)}')
            .then(r => r.json())
            .then(data => {
              if (data.success) {
                const browser = document.getElementById('file-browser');
                const items = data.contents.map(item =>
                  '<div class="file-item">' +
                  (item.type === 'directory' ? '📁' : '📄') + ' ' +
                  '<a href="' +
                  (item.type === 'directory' ?
                    '/browse?path=' + encodeURIComponent(item.path) :
                    '/static/' + encodeURIComponent(item.path)) +
                  '" class="file-link">' + item.name + '</a>' +
                  ' <small>(' + item.size + ' bytes, ' + new Date(item.lastModified).toLocaleDateString() + ')</small>' +
                  '</div>'
                ).join('');
                browser.innerHTML = '<ul class="file-list">' + items + '</ul>';
              } else {
                browser.innerHTML = '<p>❌ Error loading files: ' + data.error + '</p>';
              }
            })
            .catch(err => {
              document.getElementById('file-browser').innerHTML = '<p>❌ Network error: ' + err.message + '</p>';
            });
        </script>
      </div>
    </body>
    </html>
  `);
});

// Enhanced CORS configuration for learning opportunity
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests from Claude instances and admin interfaces
    const allowedOrigins = [
      'https://claude.ai',
      'https://console.anthropic.com',
      /^https:\/\/.*\.anthropic\.com$/,
      /^http:\/\/localhost:\d+$/,
      /^http:\/\/127\.0\.0\.1:\d+$/,
      /^https:\/\/.*\.claudelink\.thatsnice\.org$/
    ];

    // Allow no origin (server-to-server requests)
    if (!origin) return callback(null, true);

    const isAllowed = allowedOrigins.some(allowed => {
      if (typeof allowed === 'string') {
        return origin === allowed;
      } else if (allowed instanceof RegExp) {
        return allowed.test(origin);
      }
      return false;
    });

    if (isAllowed) {
      callback(null, true);
    } else {
      console.log(`CORS blocked origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Content-Type',
    'Accept',
    'Authorization',
    'X-ClaudeLink-Instance',
    'X-Admin-Token'
  ],
  exposedHeaders: ['X-Total-Count', 'X-Page-Token'],
  maxAge: 86400 // 24 hours preflight cache
};

app.use(require('cors')(corsOptions));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  const instanceId = req.headers['x-claudelink-instance'] || 'unknown';
  const adminToken = req.headers['x-admin-token'] ? 'present' : 'none';
  console.log(`[${timestamp}] ${req.method} ${req.path} - Instance: ${instanceId} - Admin: ${adminToken}`);
  next();
});

// Simple session management for admin (TODO: replace with proper OAuth)
const adminSessions = new Map();

function generateSessionToken() {
  return crypto.randomBytes(32).toString('hex');
}

function isValidAdminSession(token) {
  const session = adminSessions.get(token);
  if (!session) return false;

  // Check if session is expired (24 hours)
  if (Date.now() - session.created > 24 * 60 * 60 * 1000) {
    adminSessions.delete(token);
    return false;
  }

  return true;
}

// Admin authentication middleware
function requireAdminAuth(req, res, next) {
  const token = req.headers['x-admin-token'] || req.query.admin_token;

  // TODO: Replace with proper OAuth
  // For now, allow bypass in development
  if (process.env.NODE_ENV !== 'production' && req.query.dev_admin === 'true') {
    return next();
  }

  if (!token || !isValidAdminSession(token)) {
    return res.status(401).json({
      success: false,
      error: 'Admin authentication required',
      loginUrl: '/admin/login'
    });
  }

  next();
}

// Welcome page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>ClaudeLink Coordinator</title>
      <style>
        body { font-family: system-ui, -apple-system, sans-serif; max-width: 800px; margin: 0 auto; padding: 2rem; line-height: 1.6; }
        .header { text-align: center; border-bottom: 2px solid #e1e5e9; padding-bottom: 2rem; margin-bottom: 2rem; }
        .status { background: #d4edda; border: 1px solid #c3e6cb; padding: 1rem; border-radius: 0.5rem; margin: 1rem 0; }
        .endpoints { background: #f8f9fa; padding: 1.5rem; border-radius: 0.5rem; margin: 1.5rem 0; }
        .endpoint { font-family: Monaco, 'Courier New', monospace; background: white; padding: 0.5rem; margin: 0.5rem 0; border-radius: 0.25rem; border: 1px solid #dee2e6; }
        .admin-link { display: inline-block; background: #007bff; color: white; padding: 0.75rem 1.5rem; text-decoration: none; border-radius: 0.5rem; margin: 1rem 0; }
        .admin-link:hover { background: #0056b3; }
        .todo { background: #fff3cd; border: 1px solid #ffeaa7; padding: 1rem; border-radius: 0.5rem; margin: 1rem 0; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>🔗 ClaudeLink Coordinator</h1>
        <p>Distributed Claude Instance Coordination Service</p>
        <p><strong>Server:</strong> ${FREEBSD_SERVER} | <strong>Port:</strong> ${PORT} | <strong>Status:</strong> Running</p>
      </div>

      <div class="status">
        <h3>✅ Service Status</h3>
        <p>The ClaudeLink Coordinator is active and ready to handle requests from Claude instances.</p>
        <p><strong>Repository Path:</strong> ${GITHUB_REPO_PATH}</p>
        <p><strong>Uptime:</strong> ${Math.floor(process.uptime())} seconds</p>
      </div>

      <div class="endpoints">
        <h3>🔌 Available API Endpoints</h3>
        <div class="endpoint">GET /api/health - Service health check</div>
        <div class="endpoint">GET /api/time - Time synchronization service</div>
        <div class="endpoint">GET /api/repository - List repositories</div>
        <div class="endpoint">GET /api/repository/{repo} - Browse repository contents</div>
        <div class="endpoint">GET /api/repository/{repo}/file/* - Get file contents</div>
        <div class="endpoint">POST /api/repository/{repo}/git/{command} - Execute git operations</div>
        <div class="endpoint">POST /api/context/update - Process context updates</div>
        <div class="endpoint">GET /api/instances - List active instances</div>
      </div>

      <div style="text-align: center;">
        <a href="/admin?dev_admin=true" class="admin-link">🛠️ Administration Interface</a>
        <br><small>(Development mode - OAuth coming soon)</small>
      </div>

      <div class="todo">
        <h3>📋 Development TODO</h3>
        <ul>
          <li><strong>[HIGH]</strong> Generate SSH keys for vault to push to Github</li>
          <li><strong>[HIGH]</strong> Create vault rebuild instructions</li>
          <li><strong>[MEDIUM]</strong> Implement OAuth authentication for /admin</li>
          <li><strong>[MEDIUM]</strong> Enhanced admin interface features</li>
        </ul>
      </div>

      <div style="text-align: center; margin-top: 3rem; color: #6c757d;">
        <p>ClaudeLink Coordinator v1.0.0 | Instance: ${process.env.INSTANCE_ID || 'claudelink-dev-001'}</p>
      </div>
    </body>
    </html>
  `);
});

// Admin interface routes
app.get('/admin', requireAdminAuth, (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>ClaudeLink Admin</title>
      <style>
        body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: #f8f9fa; }
        .header { background: #343a40; color: white; padding: 1rem; }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
        .card { background: white; border-radius: 0.5rem; padding: 1.5rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .btn { background: #007bff; color: white; padding: 0.5rem 1rem; text-decoration: none; border-radius: 0.25rem; display: inline-block; margin: 0.25rem; }
        .btn:hover { background: #0056b3; }
        .btn-success { background: #28a745; }
        .btn-warning { background: #ffc107; color: #212529; }
        .btn-danger { background: #dc3545; }
        .status-good { color: #28a745; }
        .status-warn { color: #ffc107; }
        .log-entry { font-family: Monaco, 'Courier New', monospace; font-size: 0.85rem; padding: 0.5rem; background: #f8f9fa; margin: 0.25rem 0; border-radius: 0.25rem; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>🛠️ ClaudeLink Administration</h1>
        <p>Repository management and service monitoring</p>
      </div>

      <div class="container">
        <div class="grid">
          <div class="card">
            <h3>📊 Service Status</h3>
            <p><span class="status-good">●</span> Service Running</p>
            <p><strong>Uptime:</strong> ${Math.floor(process.uptime())} seconds</p>
            <p><strong>Memory:</strong> ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB</p>
            <p><strong>Node Version:</strong> ${process.version}</p>
            <a href="/api/health" class="btn" target="_blank">Health Check</a>
          </div>

          <div class="card">
            <h3>📁 Repository Management</h3>
            <p><strong>Path:</strong> ${GITHUB_REPO_PATH}</p>
            <p><strong>Server:</strong> ${FREEBSD_SERVER}</p>
            <a href="/admin/repositories" class="btn">Browse Repositories</a>
            <a href="/admin/sync" class="btn btn-success">Sync from GitHub</a>
            <a href="/admin/git" class="btn btn-warning">Git Operations</a>
          </div>

          <div class="card">
            <h3>🔗 Instance Coordination</h3>
            <p><strong>Active Instances:</strong> 1</p>
            <p><strong>Last Update:</strong> ${new Date().toLocaleString()}</p>
            <a href="/admin/instances" class="btn">View Instances</a>
            <a href="/admin/context" class="btn">Context Updates</a>
          </div>

          <div class="card">
            <h3>📋 TODO Items</h3>
            <div class="log-entry">[HIGH] Generate SSH keys for GitHub push</div>
            <div class="log-entry">[HIGH] Create vault rebuild instructions</div>
            <div class="log-entry">[MED] Implement OAuth authentication</div>
            <a href="/admin/todo" class="btn">Manage TODO</a>
          </div>
        </div>

        <div class="card" style="margin-top: 1.5rem;">
          <h3>📜 Recent Activity</h3>
          <div id="recent-logs">
            <div class="log-entry">[${new Date().toISOString()}] Service started</div>
            <div class="log-entry">[${new Date().toISOString()}] Admin interface accessed</div>
          </div>
          <a href="/admin/logs" class="btn">View Full Logs</a>
        </div>
      </div>

      <script>
        // Auto-refresh status every 30 seconds
        setInterval(() => {
          fetch('/api/health')
            .then(r => r.json())
            .then(data => {
              console.log('Status check:', data);
            })
            .catch(err => console.error('Status check failed:', err));
        }, 30000);
      </script>
    </body>
    </html>
  `);
});

// Admin sub-routes
app.get('/admin/repositories', requireAdminAuth, async (req, res) => {
  try {
    const repositories = await repoManager.listRepositories();
    res.json({
      success: true,
      repositories,
      admin: true,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      admin: true
    });
  }
});

app.post('/admin/repository/:repo/sync', requireAdminAuth, async (req, res) => {
  try {
    const { repo } = req.params;
    const result = await repoManager.executeGitCommand(repo, 'pull', ['origin', 'main']);
    res.json({
      success: true,
      syncResult: result,
      admin: true,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      admin: true
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'claudelink-coordinator',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0',
    repository: GITHUB_REPO_PATH,
    server: FREEBSD_SERVER
  });
});

// Time service endpoint
app.get('/api/time', (req, res) => {
  const now = new Date();
  res.json({
    timestamp: now.toISOString(),
    unix: Math.floor(now.getTime() / 1000),
    formatted: now.toLocaleString(),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    service: 'claudelink-coordinator'
  });
});

// Repository operations
class RepositoryManager {
  constructor(freebsdServer, basePath) {
    this.server = freebsdServer;
    this.basePath = basePath;
  }

  async executeGitCommand(repoName, command, args = []) {
    try {
      const repoPath = path.join(this.basePath, repoName);
      const fullCommand = `cd ${repoPath} && git ${command} ${args.join(' ')}`;

      console.log(`Executing: ${fullCommand}`);
      const result = execSync(fullCommand, {
        encoding: 'utf8',
        timeout: 30000,
        maxBuffer: 1024 * 1024 // 1MB buffer
      });

      return {
        success: true,
        output: result.toString().trim(),
        command: `git ${command} ${args.join(' ')}`
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        command: `git ${command} ${args.join(' ')}`
      };
    }
  }

  async listRepositories() {
    try {
      const entries = await fs.readdir(this.basePath);
      const repos = [];

      for (const entry of entries) {
        const entryPath = path.join(this.basePath, entry);
        const stat = await fs.stat(entryPath);

        if (stat.isDirectory()) {
          const gitPath = path.join(entryPath, '.git');
          try {
            await fs.access(gitPath);
            repos.push({
              name: entry,
              path: entryPath,
              isGitRepo: true,
              lastModified: stat.mtime.toISOString()
            });
          } catch {
            repos.push({
              name: entry,
              path: entryPath,
              isGitRepo: false,
              lastModified: stat.mtime.toISOString()
            });
          }
        }
      }

      return repos;
    } catch (error) {
      throw new Error(`Failed to list repositories: ${error.message}`);
    }
  }

  async getFileContent(repoName, filePath) {
    try {
      const fullPath = path.join(this.basePath, repoName, filePath);

      // Security check - ensure path is within repository
      const resolvedPath = path.resolve(fullPath);
      const repoBasePath = path.resolve(path.join(this.basePath, repoName));

      if (!resolvedPath.startsWith(repoBasePath)) {
        throw new Error('Access denied: Path outside repository bounds');
      }

      const content = await fs.readFile(resolvedPath, 'utf8');
      const stat = await fs.stat(resolvedPath);

      return {
        content,
        size: stat.size,
        lastModified: stat.mtime.toISOString(),
        path: filePath
      };
    } catch (error) {
      throw new Error(`Failed to read file: ${error.message}`);
    }
  }

  async listDirectory(repoName, dirPath = '') {
    try {
      const fullPath = path.join(this.basePath, repoName, dirPath);
      const resolvedPath = path.resolve(fullPath);
      const repoBasePath = path.resolve(path.join(this.basePath, repoName));

      if (!resolvedPath.startsWith(repoBasePath)) {
        throw new Error('Access denied: Path outside repository bounds');
      }

      const entries = await fs.readdir(fullPath);
      const items = [];

      for (const entry of entries) {
        const entryPath = path.join(fullPath, entry);
        const stat = await fs.stat(entryPath);

        items.push({
          name: entry,
          type: stat.isDirectory() ? 'directory' : 'file',
          size: stat.size,
          lastModified: stat.mtime.toISOString(),
          path: path.join(dirPath, entry)
        });
      }

      return items.sort((a, b) => {
        if (a.type !== b.type) {
          return a.type === 'directory' ? -1 : 1;
        }
        return a.name.localeCompare(b.name);
      });
    } catch (error) {
      throw new Error(`Failed to list directory: ${error.message}`);
    }
  }
}

const repoManager = new RepositoryManager(FREEBSD_SERVER, REPO_BASE_PATH);

// Repository endpoints
app.get('/api/repository', async (req, res) => {
  try {
    const repositories = await repoManager.listRepositories();
    res.json({
      success: true,
      repositories,
      server: FREEBSD_SERVER,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

app.get('/api/repository/:repo', async (req, res) => {
  try {
    const { repo } = req.params;
    const { path: dirPath = '' } = req.query;

    const contents = await repoManager.listDirectory(repo, dirPath);
    res.json({
      success: true,
      repository: repo,
      path: dirPath,
      contents,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      repository: req.params.repo,
      timestamp: new Date().toISOString()
    });
  }
});

app.get('/api/repository/:repo/file/*', async (req, res) => {
  try {
    const { repo } = req.params;
    const filePath = req.params[0]; // Everything after /file/

    const fileData = await repoManager.getFileContent(repo, filePath);
    res.json({
      success: true,
      repository: repo,
      file: fileData,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      repository: req.params.repo,
      filePath: req.params[0],
      timestamp: new Date().toISOString()
    });
  }
});

app.post('/api/repository/:repo/git/:command', async (req, res) => {
  try {
    const { repo, command } = req.params;
    const { args = [] } = req.body;

    // Validate allowed git commands
    const allowedCommands = ['status', 'log', 'diff', 'branch', 'pull', 'push', 'checkout'];
    if (!allowedCommands.includes(command)) {
      return res.status(400).json({
        success: false,
        error: `Git command '${command}' not allowed`,
        allowedCommands,
        timestamp: new Date().toISOString()
      });
    }

    const result = await repoManager.executeGitCommand(repo, command, args);
    res.json({
      ...result,
      repository: repo,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      repository: req.params.repo,
      command: req.params.command,
      timestamp: new Date().toISOString()
    });
  }
});

// Context update endpoints
app.post('/api/context/update', async (req, res) => {
  try {
    const { requestor, requests } = req.body;
    const instanceId = req.headers['x-claudelink-instance'] || requestor;

    // Process context update requests
    const results = [];
    for (const request of requests) {
      const result = await processContextUpdate(request, instanceId);
      results.push(result);
    }

    res.json({
      success: true,
      requestor,
      instanceId,
      results,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

async function processContextUpdate(request, instanceId) {
  const { type, context, target_path, changes } = request;

  try {
    switch (type) {
      case 'context_update':
        return await handleContextUpdate(context, target_path, changes, instanceId);
      default:
        return {
          success: false,
          error: `Unknown request type: ${type}`,
          request
        };
    }
  } catch (error) {
    return {
      success: false,
      error: error.message,
      request
    };
  }
}

async function handleContextUpdate(context, targetPath, changes, instanceId) {
  // For now, just log the context update
  // In future versions, this would apply changes to the actual context storage

  console.log(`Context update from ${instanceId}:`);
  console.log(`  Context: ${context}`);
  console.log(`  Target: ${targetPath}`);
  console.log(`  Changes: ${changes.format}`);

  return {
    success: true,
    applied: true,
    context,
    targetPath,
    instanceId,
    timestamp: new Date().toISOString()
  };
}

// Instance coordination endpoints
app.get('/api/instances', (req, res) => {
  // Future: Return list of active Claude instances
  res.json({
    success: true,
    instances: [
      {
        id: 'claudelink-dev-001',
        status: 'active',
        lastSeen: new Date().toISOString()
      }
    ],
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 ClaudeLink Coordinator Service started`);
  console.log(`📡 Listening on port ${PORT}`);
  console.log(`🏗️ FreeBSD server: ${FREEBSD_SERVER}`);
  console.log(`📁 Repository base: ${REPO_BASE_PATH}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('📴 Received SIGTERM, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('📴 Received SIGINT, shutting down gracefully');
  process.exit(0);
});
