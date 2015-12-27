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
  YOUTH = '524-406A.youth.final.unc.pdf'
  ADULT = '524-501.adult.final.unc.pdf'

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

    data = YAML.load_file("#{home}/data.yml")
    upc = YAML.load_file("#{home}/unit_position_codes.yml")

    load "#{home}/pdf_scout_application.rb"
    load "#{home}/pdf_scout_youth_application.rb"
    load "#{home}/pdf_scout_adult_application.rb"

    data[:families].keys.each do |family_name|
      default_data = data.select{|k,v| [:unit_number, :council, :unit_types, :boys_life_subscription].include?(k)}
      fdata = default_data.merge(data[:families][family_name])

      family_unit_types = []
      fdata[:scouts].each.with_index do |sdata, i|
        supported_units = (sdata[:unit_types] or []).concat(data[:unit_types])
        family_unit_types = family_unit_types.concat(supported_units).uniq

        supported_units.each do |unit_type|
          # only consider BL subscriptions for :troop
          ydata = fdata.dup
          if(unit_type != 'troop')
            [:boys_life_subscription].each do |key|
              ydata.delete(key)
            end
          end

          youth = PdfScoutYouthApplication.new(ydata, i, unit_type, upc)
          attrs = youth.prepare(unit_type)
          youth.print(:youth, attrs, "#{home}/prints/youth.#{attrs[:file_label]}.unc.filled.pdf")
        end
      end

      family_unit_types.each do |unit_type|
        adult = PdfScoutAdultApplication.new(fdata, unit_type, upc)
        attrs = adult.prepare(unit_type)
        adult.print(:adult, attrs, "#{home}/prints/adult.#{attrs[:file_label]}.unc.filled.pdf")
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

    {
      street: md[1], 
      city: md[2], 
      state: md[3], 
      zip: md[4]
    }
  end
  
  def parse_name(line)
    md = line.split(RE_FULL_NAME)
    {
      first: md[0], 
      middle: md[1], 
      last: md[2], 
      suffix: md[3]
    }
  end
  
  def parse_phone(line)
    md = line.gsub(/[^\d]/, '').match(RE_PHONE)
    {
      area_code: md[1], 
      prefix: md[2], 
      suffix: md[3], 
      extension: md[4]
    }
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

