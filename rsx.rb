#!/usr/bin/env ruby

require "sinatra"
require "fileutils"
require "securerandom"
require "sequel"
require "mimemagic"
require "./conf"

DB = Sequel.sqlite("files-meta.db")

DB.create_table? :files do
    primary_key :id
    String :name, unique: true, null: false
    String :mime
    String :ip
    DateTime :time, default: Sequel::CURRENT_TIMESTAMP
end

DB_FILES = DB[:files]

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

def get_file_mime(path)
    MimeMagic.by_magic(File.open(path)).type
end

def insert_file(name, ip)
    path = full_path(name)
    mime = get_file_mime(path)
    puts "insert #{name}, #{ip}, #{mime}"
    DB_FILES.insert(name: name, mime: mime, ip: ip)
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
    insert_file(name, request.ip)
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
    files = DB_FILES.where(ip: request.ip)
            .order(:time)
            .map { |file| { 
                name: file[:name],
                url: get_file_url(file[:name]),
                mime: file[:mime]
            }}
    erb :album, :locals => {
        files: files,
        album_name: request.ip
    }
end

get "/album/all" do
    files = DB_FILES.order(:time)
            .map { |file| { 
                name: file[:name],
                url: get_file_url(file[:name]),
                mime: file[:mime]
            }}
    erb :album, :locals => {
        files: files,
        album_name: "all"
    }
end
