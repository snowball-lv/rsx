#!/usr/bin/env ruby

require "sinatra"
require "fileutils"
require "securerandom"
require "./conf"

puts "BASE_URL [#{BASE_URL}]"
puts "MAX_UPLOAD_MB [#{MAX_UPLOAD_MB}]"
puts "FILE_DIR [#{FILE_DIR}]"
puts "PASSWORD [#{PASSWORD}]"

def full_path(name)
    return File.join(FILE_DIR, name)
end

def get_file_url(name)
    return "https://#{BASE_URL}/files/#{name}"
end

def rand_name()
    return SecureRandom.hex(5)
end

def get_files() 
    Dir::children(FILE_DIR)
end

def get_file_urls()
    get_files.map do |file| get_file_url(file) end
end

post "/upload" do
    img = params["img"]
    pwd = params["password"]
    if PASSWORD && pwd != PASSWORD
        halt 401, "Wrong password"
    end
    filename = img ? img["filename"] : nil
    tempfile = img ? img["tempfile"] : nil
    if filename.nil? || tempfile.nil?
        halt 400, "No file provided"
    end
    name = "#{rand_name()}#{File.extname(filename)}"
    path = full_path(name)
    # check if file by that name already exists
    if File.exist?(path)
        halt 500, "File name collision"
    end
    # check if file exceeds max size
    if tempfile.size > MAX_UPLOAD_MB * 1000 * 1000
        halt 400, "Files above #{MAX_UPLOAD_MB} MB not allowed, sorry!"
    end
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, tempfile.read)
    return get_file_url(name)
end

get "/favicon.ico" do
    send_file("./favicon.ico")
end

get "/files/:name" do
    path = full_path(params["name"])
    if File.exist?(path)
        send_file(path)
        return
    end
    send_file("./404.jpg")
end

get "/album" do
    erb :album, :locals => {
        files: get_file_urls()
    }
end
