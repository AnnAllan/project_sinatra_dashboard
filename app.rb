require "sinatra"
require "sinatra/reloader" if development?
require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'csv'

def posted_on(date_text)
  word_arr = date_text.split(" ")
  case word_arr[1]
  when "minute", "minutes"
    dif = word_arr[0].to_i * 60
  when "hour", "hours"
    dif = word_arr[0].to_i * 3600
  when "day", "days"
    dif = word_arr[0].to_i * 86400
  else
    dif = 0
  end
  return Time.now - dif
end

def new_search_link(keyword_string="javascript", loc="Chattanooga, TN")
  loc_format = loc.split(", ")

  return "https://www.dice.com/jobs/advancedResult.html?for_one=#{keyword_string}&for_all=&for_exact=&for_none=&for_jt=junior&for_com=&for_loc=#{loc_format[0]}%2C+#{loc_format[1]}&sort=relevance&limit=100&radius=20"
end

get '/' do
  session["agent"] = Mechanize.new {|a| a.user_agent_alias = 'Windows Chrome'}
  session["agent"].history_added = Proc.new {sleep 0.5}
  page = session["agent"].get('https://www.dice.com/jobs/advancedResult.html?for_one=ruby&for_all=&for_exact=&for_none=&for_jt=junior&for_com=&for_loc=Washington%2C+DC&sort=relevance&limit=100&radius=0')
  session["list"] = []
  page.parser.css(".complete-serp-result-div").each do |ad|
    session["list"] << [(ad.at_css(".serp-result-content h3 a")['title']), ( ad.at_css(".employer span[2]")['title']), (ad.at_css(".serp-result-content h3 a")['href']), (posted_on(ad.at_css(".posted").text)), (ad.at_css(".serp-result-content input")['id']), (ad.at_css(".serp-result-content h3 a")['value']), (ad.at_css(".location")['title'])]
    end
  erb :index
end

post '/new_search' do
  erb :search_form
end

post '/search_keyword' do
  session["search_words"] = params[:keywords]
  session["search_loc"] = params[:loc]
  session["agent"] = Mechanize.new {|a| a.user_agent_alias = 'Windows Chrome'}
  session["agent"].history_added = Proc.new {sleep 0.5}
  page = session["agent"].get(new_search_link(session["search_words"], session["search_loc"]))
  session["list"] = nil
  session["list"] = []
  page.parser.css(".complete-serp-result-div").each do |ad|
    session["list"] << [(ad.at_css(".serp-result-content h3 a")['title']), ( ad.at_css(".employer span[2]")['title']), (ad.at_css(".serp-result-content h3 a")['href']), (posted_on(ad.at_css(".posted").text)), (ad.at_css(".serp-result-content input")['id']), (ad.at_css(".serp-result-content h3 a")['value']), (ad.at_css(".location")['title'])]
    end
  erb :index
end
