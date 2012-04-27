require 'nokogiri'
require 'uri'
require 'net/http'
require 'rack'

class Inliner
  def initialize url, options = {}
    @options = options
    @doc = Nokogiri::HTML(Net::HTTP.get(URI.parse(url)))
  end

  def inline_css
    nodes = @doc.css('link[rel="stylesheet"][href]')
    return false unless nodes.count > 0
    nodes.each do |node|
      file = file_for node
      next if !file
      inline = Nokogiri::XML::Node.new 'style', @doc
      inline.content = file['contents']
      node.before inline
      node.remove
    end
  end

 def inline_js
    nodes = @doc.css('script[src]')
    return false unless nodes.count > 0
    nodes.each do |node|
      file = file_for node
      next if !file
      inline = Nokogiri::XML::Node.new 'script', @doc
      inline.content = file['contents']
      node.before inline
      node.remove
    end
  end

  def inline_images
    nodes = @doc.css('img')
    return false unless nodes.count > 0
    nodes.each do |node|
      file = file_for node
      next if !file
      img = node.clone
      ext = File.extname(file['path'])
      img['src'] = "data:#{Rack::Mime.mime_type(File.extname(file['path']))};base64,#{[file['contents']].pack('m')}"
      img['alt'] = node['alt'] if node['alt']
      node.before img
      node.remove
    end
  end

  def to_html
    return @doc.to_s
  end

  def inline
    inline_css
    inline_js
    inline_images
    to_html
  end

  private
  def file_for node
    path = case node.name
    when 'script'
      node['src']
    when 'img'
      node['src']
    when 'link'
      node['href']
    end
    return false unless path
    contents = Net::HTTP.get(URI.parse(path))
    {'contents' => contents, 'path' => path}
  end
end
