require 'nokogiri'
require 'uri'
require 'net/http'
require 'rack'
require "inliner/version"
require 'em-http-request'
require 'pp'

module Inliner
 class Inline
    def initialize(url)
      unless validate_url(url)
        raise ArgumentError, "#{url} is not a valid URL!"
      end

      @assets = {}
      @url = URI.parse(url)
      EM.run do
        http = EM::HttpRequest.new(@url, :connect_timeout => 5, :inactivity_timeout => 10).get :redirects => 1
        http.callback {
          @doc = Nokogiri::HTML(http.response)
          EM.stop
        }
      end
    end

    def validate_url(url)
      !(url =~ URI::regexp).nil?
    end

    def inline_asset(node)
      contents = asset_contents(asset_uri(node))
      return if !contents
      node.before inline_node(contents, node)
      node.remove
    end

    def inline_node(contents, node)
      case node.name
      when 'img'
        inline = node.clone
        inline['src'] = create_data_uri(asset_uri(node), contents)
        inline['alt'] = node['alt'] if node['alt']
      when 'link'
        inline = Nokogiri::XML::Node.new 'style', @doc
        inline.content = inline_css_assets(contents)
      else
        inline = Nokogiri::XML::Node.new node.name, @doc
        inline.content = contents
      end
      inline
    end

    def inline_css_assets(contents)
      css_urls = Hash[contents.scan(/url\([\'"]?(.+?)[\'"]?\)/).map { |u|
        uri = @url + u[0]
        [u[0], uri.to_s]
      }]

      unless css_urls.empty?
        get_urls(css_urls.values)
        css_urls.each do |path, full|
          data_uri = create_data_uri(path, asset_contents(full))
          contents = contents.gsub(path, data_uri)
        end
      end
      contents
    end

    def create_data_uri(path, contents)
      mime = Rack::Mime.mime_type(File.extname(path))
      "data:#{Rack::Mime.mime_type(File.extname(path))};base64,#{[contents].pack('m').gsub(/\n/, "")}"
    end

    def to_html
      return @doc.to_s
    end

    def get_urls(urls)
      assets = {}
      EventMachine.run do
        multi = EventMachine::MultiRequest.new
        urls.uniq.each_with_index do |url, idx|
          begin
            http = EventMachine::HttpRequest.new(url, :connect_timeout => 1)
            req = http.get :redirects => 1
          rescue URI::InvalidURIError(e)
            p e.backtrace
          end
          multi.add url, req
        end

        multi.callback do
          multi.responses[:callback].each do |idx, r|
            #p idx
            assets[idx] = r.response
          end
          EventMachine.stop
        end
      end
      assets
    end

    def inline
      assets = @doc.css('img') + @doc.css('link[rel="stylesheet"][href]') + @doc.css('script[src]')
      urls = assets.map {|node| asset_uri(node)}

      @assets = get_urls urls
      assets.each do |node|
        inline_asset node
      end
      to_html
    end

    def asset_uri(node)
      path = case node.name
      when 'script'
        node['src']
      when 'img'
        node['src']
      when 'link'
        node['href']
      end
      return false unless path

      uri = @url + path
      uri.to_s
    end

    def asset_contents(uri)
      @assets[uri] || Net::HTTP.get(URI.parse(uri))
    end
  end
end
