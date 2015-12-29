require 'bundler/setup'
require 'pdf-forms'
require 'time'
require 'yaml'
require 'byebug'

=begin
irb

load '/Users/davidvezzani/Documents/journal/scm/pdf-scouts/pdf_scout_application.rb'
PdfScoutApplication.process
=end

class PdfScoutApplication
  attr_accessor :data, :unit_position_codes, :file_label
  attr_reader :pdftk

  HOME = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'
  YOUTH = '524-406A.youth.single-page.final.unc.pdf'
  ADULT = '524-501.adult.single-page.final.unc.pdf'
  DATA_FILE = 'data-all.yml'

  RE_ADDRESS = /^([^,]+), *([^,]+), ([A-Z]+) ([\d-]+)$/
  RE_FULL_NAME = /[[:space:],]/
  RE_PHONE = /^(\d{3})(\d{3})(\d{4})(\d*)$/
  RE_EMAIL = /^([^\@]+)\@(.*)$/

  def initialize(data, unit_position_codes)
    @data = data
    @unit_position_codes = unit_position_codes
    @pdftk = PdfForms.new('/usr/local/bin/pdftk')
  end

  def self.process
    home = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'

    data = YAML.load_file("#{HOME}/#{DATA_FILE}")
    # debugger
    upc = YAML.load_file("#{HOME}/unit_position_codes.yml")

    load "#{HOME}/pdf_scout_application.rb"
    load "#{HOME}/pdf_scout_youth_application.rb"
    load "#{HOME}/pdf_scout_adult_application.rb"

    data[:families].keys.each do |family_name|
    # %w{North}.each do |family_name|
      puts "processing #{family_name} members..."

      default_data = data.select{|k,v| [:unit_number, :council, :unit_types, :boys_life_subscription].include?(k)}
      fdata = default_data.merge(data[:families][family_name])

      # only consider BL subscriptions for :troop
      filtered = fdata.dup
      [:boys_life_subscription].each do |key|
        filtered.delete(key)
      end

      family_unit_types = []
      fdata[:scouts].each.with_index do |sdata, i|

        supported_units = (sdata[:unit_types] or data[:unit_types])
        # supported_units = supported_units.concat(data[:unit_types]) unless supported_units.include?(%w{cub webelos})
        family_unit_types = family_unit_types.concat(supported_units).uniq
        puts "processing #{sdata[:full_name]} (#{supported_units.inspect}..."

        yboys_life_applied = false
        supported_units.each do |unit_type|

          ydata = if(%w{troop cub webelos}.include?(unit_type) and !yboys_life_applied)
                    yboys_life_applied = true
                    fdata
                  else
                    filtered
                  end

          Thread.new{
          youth = PdfScoutYouthApplication.new(ydata, i, unit_type, upc)
          attrs = youth.prepare(unit_type)
          youth.print(:youth, attrs, "#{HOME}/prints/youth.#{attrs[:file_label]}.unc.filled.pdf")
          }
        end
      end

      fdata[:adults].each.with_index do |adata, i|
        supported_units = family_unit_types.concat((adata[:unit_types] or data[:unit_types])).uniq
        supported_units.map!{|x| (x == 'cub') ? 'pack' : x }
        puts "processing #{adata[:full_name]} (#{supported_units.inspect}..."

        supported_units.each do |unit_type|
          
          Thread.new{
          adult = PdfScoutAdultApplication.new(filtered, i, unit_type, upc)
          attrs = adult.prepare(unit_type)
          adult.print(:adult, attrs, "#{HOME}/prints/adult.#{attrs[:file_label]}.unc.filled.pdf")
          }
        end
      end
    end
  end

  def parse_date(date)
    if(date.is_a?(String))
      date = Time.parse(date)
    end

    {
      day: date.strftime("%d"), 
      month: date.strftime("%m"), 
      year: date.strftime("%Y")
    }
  end
  
  def parse_email(line)
    md = line.match(RE_EMAIL)
    {
      username: clean(md[1], false), 
      domain: clean(md[2], false)
    }
  end
  
  def parse_address(line)
    md = line.to_s.match(RE_ADDRESS)
    # debugger if md.nil?

    {
      street: md[1], 
      city: md[2], 
      state: md[3], 
      zip: md[4]
    }
  end
  
  def parse_name(line)
    md = line.split(RE_FULL_NAME)

    middle = ''
    suffix = ''
    last = ''
    if(md.length < 3)
      last = md[1]
    else
      middle = md[1]

      if(md.length > 2 and md.last and md.last.downcase.match(/^(jr|sr|[ivx]+)/))
        middle = '' if md.length == 3
        last = md[-2]
        suffix = md.last
      else
        last = md.last
      end
    end

    {
      first: md[0], 
      middle: middle, 
      last: last, 
      suffix: suffix
    }
  end
  
  def parse_phone(line)
    if(md = line.gsub(/[^\d]/, '').match(RE_PHONE))
    {
      area_code: md[1], 
      prefix: md[2], 
      suffix: md[3], 
      extension: md[4]
    }
    end
  end


  def clean(value, pattern=/\./)
    value = value.to_s.upcase
    value = value.gsub(pattern, '') if pattern
    value
  end

  def fields(type)
    pdf_template = case(type)
    when :adult
      "#{HOME}/#{ADULT}"
    when :youth
      "#{HOME}/#{YOUTH}"
    end
    @pdftk.get_field_names pdf_template
  end

  def print(type, attrs, filename = nil)
    pdf_template = case(type)
    when :adult
      "#{HOME}/#{ADULT}"
    when :youth
      "#{HOME}/#{YOUTH}"
    end
    
    filename = if(filename.nil?)
      re = /\.(?=pdf$)/
      filename, extension = pdf_template.split(re)
      "#{filename}.filled.#{extension}"
    else
      filename
    end
    
    @pdftk.fill_form pdf_template, "#{filename}", attrs
    "#{filename}"
  end
end

require_relative 'pdf_scout_adult_application'
require_relative 'pdf_scout_youth_application'

