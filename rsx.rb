#!/usr/bin/env ruby

#require "bundler/setup"

require "sinatra"
require "fileutils"
require "securerandom"
require "sequel"
require "mimemagic"
require "mini_magick"
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

THUMB_DIR = File.join(FILE_DIR, "thumbs")
puts "THUMB_DIR [#{THUMB_DIR}]"

THUMB_DIM = 128

def get_full_path(name)
    return File.join(FILE_DIR, name)
end

def full_path(name)
    return get_full_path(name)
end

def get_thumb_path(name)
    return File.join(THUMB_DIR, name)
end

def get_file_url(name)
    return "https://#{BASE_URL}/files/#{name}"
end

def get_thumb_url(name)
    return "https://#{BASE_URL}/files/thumbs/#{name}"
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
    mime = MimeMagic.by_magic(File.open(path))
    return mime ? mime.type : ""
end

def insert_file(name, ip)
    path = full_path(name)
    mime = get_file_mime(path)
    puts "insert #{name}, #{ip}, #{mime}"
    DB_FILES.insert(name: name, mime: mime, ip: ip)
end

def make_thumb(name)
    puts "Making thumb for #{name}"
    mime = get_file_mime(get_full_path(name))
    return unless mime.start_with?("image/")
    img = MiniMagick::Image.open(get_full_path(name))
    if img.width > img.height
        height = img.height / (img.width / THUMB_DIM.to_f)
        img.resize("#{THUMB_DIM}x#{height.to_i}")
    else
        width = img.width / (img.height / THUMB_DIM.to_f)
        img.resize("#{width.to_i}x#{THUMB_DIM}")
    end
    thumbpath = get_thumb_path(name)
    FileUtils.mkdir_p(File.dirname(thumbpath))
    img.write(thumbpath)
end

def gen_all_thumbs()
    Dir.each_child(FILE_DIR) do |f|
        if File.file?(get_full_path(f)) && !File.exist?(get_thumb_path(f))
            make_thumb(f)
        end
    end
end

# startup tasks
gen_all_thumbs()

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
    make_thumb(name)
    return get_file_url(name)
end

get "/favicon.ico" do
    send_file("./favicon.ico")
end

get "/files/:name" do
    path = full_path(params["name"])
    if File.exist?(path)
        send_file(path)
    end
    pass
end

get "/files/thumbs/:name" do
    path = get_thumb_path(params["name"])
    if File.exist?(path)
        send_file(path)
    end
    pass
end

get "/album" do
    files = DB_FILES.where(ip: request.ip)
            .order(:time)
	    .reverse
            .map { |file| { 
                name: file[:name],
                url: get_file_url(file[:name]),
                mime: file[:mime],
                thumb_url: get_thumb_url(file[:name])
            }}
    erb :album, :locals => {
        files: files,
        album_name: request.ip
    }
end

get "/album/all" do
    files = DB_FILES.order(:time)
	    .reverse
            .map { |file| { 
                name: file[:name],
                url: get_file_url(file[:name]),
                mime: file[:mime],
                thumb_url: get_thumb_url(file[:name])
            }}
    erb :album, :locals => {
        files: files,
        album_name: "all"
    }
end

not_found do
    send_file("./404.jpg", :status => 404)
end
