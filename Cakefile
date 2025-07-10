# ClodForest Cakefile
# Delegates to modular task system in cake/

tasks = require './cake'

# Register all tasks
for name, {description, action} of tasks
  task name, description, action
