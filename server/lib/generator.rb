require 'faker'
require 'csv'
require 'mixpanel-ruby'

#
# class MyCustomError < StandardError
#   ClientError = Class.new(self)
#
#   Unauthorized = Class.new(ClientError)
# end


class Dataset
  attr_accessor :users
  attr_accessor :logger
  attr_reader :mixpanel_api_key

  def initialize(mixpanel_api_key = nil, size = 1000, logger = Logger.new(STDOUT))
    @size = size
    @users = []
    @mixpanel_api_key = mixpanel_api_key
    @logger = logger
    populate_users
    add_purchase_behavior
  end

  def to_csv
    dirname = File.expand_path(File.dirname(__FILE__))
    filename = "#{ DateTime.now.strftime('%d-%m-%y-%H-%M-%S') }-retention-dataset.csv"

    CSV.open(File.join(dirname , 'datasets', filename), 'w') do |csv|
      @users.each do |user|
        csv << user.csv_serialize
      end
      puts "CSV created."
    end
  end

  def to_mixpanel
    # TODO Throw Exception
    return if mixpanel_api_key&.empty?


    tracker = Mixpanel::Tracker.new(mixpanel_api_key)
    users.each do |user|
      tracker.people.set(user.id,
        '$first_name':         user.first_name,
        '$last_name':          user.last_name,
        '$email':              user.email,
        'Gender':              user.gender,
        '$country_code':       user.country,
        '$created':            user.created_at,
        'january_purchases':   user.january_purchases,
        'february_purchases':  user.february_purchases,
        'march_purchases':     user.march_purchases,
        'april_purchases':     user.april_purchases,
        'may_purchases':       user.may_purchases,
        'june_purchases':      user.june_purchases,
        'july_purchases':      user.july_purchases,
        'august_purchases':    user.august_purchases,
        'september_purchases': user.september_purchases,
        'october_purchases':   user.october_purchases,
        'november_purchases':  user.november_purchases,
        'december_purchases':  user.december_purchases,
        'first_purchase_date': user.date_of_first_purchase)
    end
  end

  private

  def populate_users
    @size.times.collect do |i|
      @users << User.new(i + 1)
    end
  end

  def add_purchase_behavior
    @users.each { |u| add_purchase_behavior_to_user(u) }
  end

  def add_purchase_behavior_to_user(user)
    add_purchases_to_current_month(user) unless user.churned?
    case user.retention_type
    when 'new'         then new_user_purchase_behavior(user)
    when 'current'     then current_user_purchase_behavior(user)
    when 'resurrected' then resurrected_user_purchase_behavior(user)
    when 'churned'     then churned_user_purchase_behavior(user)
    end
  end

  def add_purchases_to_current_month(user)
    current_date           = Date.today
    current_month_in_words = current_date.strftime('%B').downcase

    user.send("#{current_month_in_words}_purchases=", 2)
  end

  def new_user_purchase_behavior(user)
    current_date = Date.today
    user.date_of_first_purchase = current_date.strftime('%Y-%m-01T%T')
  end

  def current_user_purchase_behavior(user)
    previous_month          = Date.today.prev_month
    previous_month_in_words = previous_month.strftime('%B').downcase

    user.send("#{previous_month_in_words}_purchases=", 3)
    user.date_of_first_purchase = previous_month.strftime('%FT%T')
  end

  def resurrected_user_purchase_behavior(user)
    month_number        = Date.today.month
    random_month_number = rand(2..month_number - 1)
    random_past_month   = Date.today.prev_month(random_month_number)
    random_past_month_in_words = random_past_month.strftime('%B').downcase

    user.send("#{random_past_month_in_words}_purchases=", 1)
    user.date_of_first_purchase = random_past_month.strftime('%Y-%m-02T%T')
  end

  def churned_user_purchase_behavior(user)
    resurrected_user_purchase_behavior(user)
  end
end

class User
  attr_accessor :id,
                :january_purchases,
                :february_purchases,
                :march_purchases,
                :april_purchases,
                :may_purchases,
                :june_purchases,
                :july_purchases,
                :august_purchases,
                :september_purchases,
                :october_purchases,
                :november_purchases,
                :december_purchases,
                :date_of_first_purchase

  attr_reader :first_name, :last_name, :gender, :country,
              :retention_type, :email, :created_at

  GENDER_TYPES            = %w[other female male].freeze
  CREATION_PERIOD_IN_DAYS = 365

  def initialize(id = nil, retention_type = generate_retention_type)
    @id             = id
    @retention_type = retention_type
    @gender         = GENDER_TYPES.sample
    @country        = Countries.select_random
    @created_at     = generate_creation_date
    create_blank_purchase_history
    generate_fake_persona
  end

  def csv_serialize
    [
      id,
      first_name,
      last_name,
      email,
      gender,
      country,
      created_at,
      january_purchases,
      february_purchases,
      march_purchases,
      april_purchases,
      may_purchases,
      june_purchases,
      july_purchases,
      august_purchases,
      september_purchases,
      october_purchases,
      november_purchases,
      december_purchases,
      date_of_first_purchase
    ]
  end

  def churned?
    retention_type == 'churned'
  end

  private

  def generate_retention_type
    case rand(100)
    when 0..15   then 'new'
    when 15..50  then 'current'
    when 50..70  then 'resurrected'
    when 70..100 then 'churned'
    end
  end

  def create_blank_purchase_history
    @date_of_first_purchase = nil
    @january_purchases      = 0
    @february_purchases     = 0
    @march_purchases        = 0
    @april_purchases        = 0
    @may_purchases          = 0
    @june_purchases         = 0
    @july_purchases         = 0
    @august_purchases       = 0
    @september_purchases    = 0
    @october_purchases      = 0
    @november_purchases     = 0
    @december_purchases     = 0
  end

  def generate_fake_persona
    @first_name = Faker::Name.first_name
    @last_name  = Faker::Name.last_name
    @email      = Faker::Internet.email
  end

  def generate_creation_date
    Faker::Time.backward(CREATION_PERIOD_IN_DAYS).strftime('%FT%T')
  end
end

class Countries
  TOTAL_COUNTRIES = 10

  def self.select_random
    all.sample
  end

  def self.all
    TOTAL_COUNTRIES.times.collect { Faker::Address.country }
  end
end

if __FILE__== $0
  Dataset.new.to_csv
end
