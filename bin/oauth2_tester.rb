#!/usr/bin/env ruby
#
# oauth2_tester.rb
# Copyright (C) 2015 Daisuke Shimamoto <shimamoto@lifeistech.co.jp>
#
# Distributed under terms of the MIT license.
#

# Usage: ruby oauth2_tester.rb AUTHORIZATION_URL APP_ID APP_SECRET SCOPE

# gem install oauth2 launchy awesome_print
require 'oauth2'
require 'launchy'
require 'awesome_print'

site          = ARGV[0]
client_id     = ARGV[1]
client_secret = ARGV[2]
scope         = ARGV[3]
redirect_uri  = 'urn:ietf:wg:oauth:2.0:oob'


client = OAuth2::Client.new(client_id, client_secret, site: site)

url_params = { redirect_uri: redirect_uri }
url_params.merge!(scope: scope) if scope

authorization_url = client.auth_code.authorize_url(url_params)
Launchy.open(authorization_url)

print "Please enter the authorization code here > "
authorization_code = $stdin.gets.chomp

puts "Authorization Code is #{authorization_code}"

token = client.auth_code.get_token(authorization_code, redirect_uri: redirect_uri)

puts "Access Token: #{token.token}"

while true do
  print "Please enter url> "
  url = $stdin.gets.chomp

  begin
    response = token.get(url)
    ap response
  rescue => error
    ap error
  end
end
