require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @chapters = File.readlines("data/toc.txt")
end

helpers do

  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, idx|
      "<p id=paragraph#{idx}>#{line}</p>"
    end.join
  end

  def highlight(text, word)
    text.gsub(word, %(<strong>#{word}</strong>))
  end

end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  @title = "Chapter #{number}: #{@chapters[number - 1]}"

  redirect "/" unless (1..@chapters.size).include? number || params[:number] != number.to_s

  @content = File.read("data/chp#{number}.txt")

  erb :chapter
end

not_found do
  redirect "/"
end

def each_chapter
  @chapters.each_with_index do |name, idx|
    number = idx + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def chapters_matching(query)
  results = []

  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      matches[index] = paragraph if paragraph.include?(query)
    end
    results << {number: number, name: name, paragraphs: matches} if matches.any?
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end