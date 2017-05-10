require "sinatra"
require "sinatra/reloader" if development?
require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'csv'
require 'pp'
require 'httparty'
require 'envyable'

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

def format_company_name(name)
  name_arr = name.split(" ")
  formated_name = []
  name_arr.each do |item|
    formated_name << item.capitalize
  end
  return formated_name.join(" ")
end

get '/' do
  session["agent"] = Mechanize.new {|a| a.user_agent_alias = 'Windows Chrome'}
  session["agent"].history_added = Proc.new {sleep 0.5}
  page = session["agent"].get('https://www.dice.com/jobs/advancedResult.html?for_one=ruby&for_all=&for_exact=&for_none=&for_jt=junior&for_com=&for_loc=Washington%2C+DC&sort=relevance&limit=100&radius=0')
  list = []
  i = 0
  page.parser.css(".complete-serp-result-div").each do |ad|
    msg = "Information not available"
    employer_name = ad.at_css(".employer span[2]")['title']
    puts employer_name
    if employer_name != nil
      name = format_company_name(employer_name)
      comp = CompanyProfile.prof(format_company_name(name))
      if (comp != nil) && (comp["response"] != nil) && (comp["response"]["employers"] != nil) && (comp["response"]["employers"][0] != nil)
        puts "full info _____________________________"
        not_nil_arr = comp["response"]["employers"][0]
        list[i] = [(ad.at_css(".serp-result-content h3 a")['title']), (ad.at_css(".employer span[2]")['title']), (ad.at_css(".serp-result-content h3 a")['href']), (posted_on(ad.at_css(".posted").text)), (ad.at_css(".serp-result-content input")['id']), (ad.at_css(".serp-result-content h3 a")['value']), (ad.at_css(".location")['title']), not_nil_arr["id"], not_nil_arr["overallRating"], not_nil_arr["ratingDescription"], not_nil_arr["cultureAndValuesRating"], not_nil_arr["seniorLeadershipRating"], not_nil_arr["compensationAndBenefitsRating"], not_nil_arr["careerOpportunityRating"], not_nil_arr["workLifeBalanceRating"], not_nil_arr["featuredReview"]["headline"], not_nil_arr["featuredReview"]["pros"],
        not_nil_arr["featuredReview"]["cons"]]
        puts list[i]

      else
        puts "no company info _____________________________"
        list[i] = [(ad.at_css(".serp-result-content h3 a")['title']), (ad.at_css(".employer span[2]")['title']), (ad.at_css(".serp-result-content h3 a")['href']), (posted_on(ad.at_css(".posted").text)), (ad.at_css(".serp-result-content input")['id']), (ad.at_css(".serp-result-content h3 a")['value']), (ad.at_css(".location")['title']), msg, msg, msg, msg, msg, msg, msg, msg, msg, msg, msg]
        puts list[i]
      end

    else
      puts "no company name _____________________________"
      list[i] = [(ad.at_css(".serp-result-content h3 a")['title']), (ad.at_css(".employer span[2]")['title']), (ad.at_css(".serp-result-content h3 a")['href']), (posted_on(ad.at_css(".posted").text)), (ad.at_css(".serp-result-content input")['id']), (ad.at_css(".serp-result-content h3 a")['value']), (ad.at_css(".location")['title']), msg, msg, msg, msg, msg, msg, msg, msg, msg, msg, msg]
      puts list[i]
    end
    i += 1
  end
  session["list"] = list
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

post '/use_loc' do
  session["agent"] = Mechanize.new {|a| a.user_agent_alias = 'Windows Chrome'}
  session["agent"].history_added = Proc.new {sleep 0.5}
  session["add"] = request.ip
  home = "pipkin.home.dyndns.org"
  if Sinatra::Base.development?
    session["add"] = home
  end
  session["address"] = Locator.city(session["add"])
  page = session["agent"].get(new_search_link("programming", session["address"]))
  session["list"] = nil
  session["list"] = []
  page.parser.css(".complete-serp-result-div").each do |ad|
    session["list"] << [(ad.at_css(".serp-result-content h3 a")['title']), ( ad.at_css(".employer span[2]")['title']), (ad.at_css(".serp-result-content h3 a")['href']), (posted_on(ad.at_css(".posted").text)), (ad.at_css(".serp-result-content input")['id']), (ad.at_css(".serp-result-content h3 a")['value']), (ad.at_css(".location")['title'])]
    end
  erb :index

end

class Locator
  include HTTParty
  def self.city(add)
    @response = HTTParty.get("http://freegeoip.net/json/#{add}")
    @location =  JSON.parse(@response.body)
    return "#{@location["city"]}, #{@location["region_code"]}"
  end
end

class CompanyProfile
  attr_accessor :prof
  include HTTParty
  Envyable.load('config/env.yml')
  API_KEY = ENV["API_KEY"]
  BASE_URI = "http://api.glassdoor.com/api/api.htm?v=1&format=json&t.p=149465&t.k=#{API_KEY}"

  def self.prof(q)
     @options = {:query => {:action => "employers", :q => q}}
    @response = HTTParty.get(BASE_URI, @options)
    @prof = JSON.parse(@response.body)
    return @prof
  end
end
