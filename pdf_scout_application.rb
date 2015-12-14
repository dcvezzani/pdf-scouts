require 'bundler/setup'
require 'pdf-forms'
require 'time'

=begin
irb

home = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'

require 'yaml'
data = YAML.load_file("#{home}/data.yml")
upc = YAML.load_file("#{home}/unit_position_codes.yml")

load "#{home}/pdf_scout_application.rb"
load "#{home}/pdf_scout_youth_application.rb"

data[:families]["Vezzani"]

youth = PdfScoutYouthApplication.new(data, 1, :troop, upc)

attrs = youth.prepare(:troop)
File.open("#{home}/chk-youth.txt", "w"){|f| f.write attrs.inspect
  f.write "\n\n"
  f.write attrs.keys.map(&:to_s).sort.map{|k| "#{k}: #{attrs[k.to_sym]}"}.join("\n")
}
# File.open("#{home}/youth-fields.txt", "w"){|f| f.write youth.fields(:youth).sort.join("\n") }

youth.print(attrs)

`open #{home}/524-501.adult.final.unc.filled.pdf`
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
