require 'bundler/setup'
require 'pdf-forms'
require 'time'

class PdfScoutApplication
  attr_accessor :data, :unit_position_codes
  attr_reader :pdftk

  HOME = '/Users/davidvezzani/Dropbox/20151101-pdf-parsing'
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
      username: clean(md[1]), 
      domain: clean(md[2])
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


  def clean(value)
    value.to_s.upcase.gsub(/\./, '')
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
end
