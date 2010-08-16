#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "mongo"

connection = Mongo::Connection.new
db = connection["test"]
users = db.collection("users")
posts = db.collection("posts")

users.insert("username" => "ereslibre", "name" => "Rafael", "surname" => "Fernández")
users.insert("username" => "foobar", "name" => "Foo", "surname" => "Bar")

posts.insert("user" => users.find_one("username" => "ereslibre")["_id"],
             "title" => "Title ereslibre")
posts.insert("user" => users.find_one("username" => "ereslibre")["_id"],
             "title" => "Title 2 ereslibre")
posts.insert("user" => users.find_one("username" => "foobar")["_id"],
             "title" => "Title foobar")

users.find().each { |user|
  puts "Posts by #{user["name"]} (#{user["username"]})"
  posts.find("user" => user["_id"]).each { |post|
    puts post["title"]
  }
}

connection.drop_database("test")
