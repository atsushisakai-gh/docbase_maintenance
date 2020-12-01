#!/usr/env/ruby

require 'httparty'
require 'uri'
require 'thor'
require 'pry'

class DocBase
  include HTTParty
  base_uri 'api.docbase.io'

  def initialize(access_token)
    @headers = { 'X-DocBaseToken': access_token, 'Content-Type': 'application/json' }
  end

  def posts(team:, query:)
    self.class.get("/teams/#{team}/posts", query: query, headers: @headers)
  end

  def update_group(team, post_id, group_id)
    binding.pry
    self.class.patch("/teams/#{team}/posts/#{post_id}", data: { scope: 'group', groups: [ group_id ] }, headers: @headers)
  end
end


class MaintenanceGroup < Thor

  desc '公開範囲変更', '公開範囲変更'
  method_options :dry_run => true
  method_options :access_token => :string
  method_options :team => :string
  method_options :query => :string
  method_options :to_group_id => :numeric
  def exec
    docbase = DocBase.new(options.access_token)

    response = docbase.posts(team: options.team, query: { q: options.query } )

    say '---- 以下のドキュメントが検索にヒットしました'
    response['posts'].each do |p|
      puts "#{p['title']} => #{p['url']}"
    end
    if response['posts'].empty?
      say 'お探しのドキュメントは存在しません'
      exit 0
    end
    exit 0 if options.dry_run?

		if yes? "--- これらのドキュメントの公開範囲変更を進めますがよろしいですか？", :bold
      ids = response['posts'].map { |p| p['id'] }
      ids.each do |id|
        `curl -H 'X-DocBaseToken: #{options.access_token}' -H 'Content-Type: application/json' -X PATCH -d '{ "scope": "group", "groups": [ #{options.to_group_id} ], "notice": false }' https://api.docbase.io/teams/#{options.team}/posts/#{id}`
      end
      say '変更しました', [:magenta, :bold]
    else
      say '何もせずに終了します'
    end
  end
end
