require 'bundler/setup'
require_relative 'pdf_scout_application'

=begin
require 'yaml'
data = YAML.load_file('/Users/davidvezzani/Dropbox/20151101-pdf-parsing/data.yml')
upc = YAML.load_file('/Users/davidvezzani/Dropbox/20151101-pdf-parsing/unit_position_codes.yml')

# load '/Users/davidvezzani/Dropbox/20151101-pdf-parsing/pdf_scout_application.rb'
load '/Users/davidvezzani/Dropbox/20151101-pdf-parsing/pdf_scout_adult_application.rb'
adult = PdfScoutAdultApplication.new(data, upc)

attrs = adult.prepare(:troop)
File.open("chk-adult.txt", "w"){|f| f.write attrs.inspect
  f.write "\n\n"
  f.write attrs.keys.map(&:to_s).sort.map{|k| "#{k}: #{attrs[k.to_sym]}"}.join("\n")
}
# File.open("adult-fields.txt", "w"){|f| f.write adult.fields(:adult).sort.join("\n") }

adult.print(attrs)
=end

=begin
irb

home = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'

require 'yaml'
data = YAML.load_file("#{home}/data.yml")
upc = YAML.load_file("#{home}/unit_position_codes.yml")

load "#{home}/pdf_scout_application.rb"
load "#{home}/pdf_scout_adult_application.rb"
family_data = (data[:families]["Vezzani"]).merge(data.select{|k,v| [:unit_number, :council, :unit_types, :boys_life_subscription].include?(k)})
adult = PdfScoutAdultApplication.new(family_data, :troop, upc)

attrs = adult.prepare(:troop)
File.open("#{home}/chk-adult.txt", "w"){|f| f.write attrs.inspect
  f.write "\n\n"
  f.write attrs.keys.map(&:to_s).sort.map{|k| "#{k}: #{attrs[k.to_sym]}"}.join("\n")
}
# File.open("#{home}/adult-fields.txt", "w"){|f| f.write adult.fields(:adult).sort.join("\n") }

adult.print(:adult, attrs, "#{home}/adult.#{attrs[:file_label]}.unc.filled.pdf")

`open #{home}/adult.#{attrs[:file_label]}.unc.filled.pdf`
=end


class PdfScoutAdultApplication < PdfScoutApplication

  def initialize(data, unit_type, unit_position_codes)
    super(data, unit_position_codes)
  end

  def file_label(unit_type)
    # return file_label unless file_label.nil?
    name_values = parse_name(data[:adult][:full_name])
    {file_label: "#{name_values[:last]} #{name_values[:first]} #{name_values[:middle]} #{name_values[:suffix]} #{unit_type}".strip.downcase.gsub(/\W+/, '-')}
  end
  
  def expiration_date(todays_date)
    date = parse_date(todays_date)
    {
      p5_expiration_date_day: clean(date[:day]), 
      p5_expiration_date_month: clean(date[:month]), 
      p5_expiration_date_year: clean(date[:year])
    }
  end
  
  def employment
    {
      p5_occupation: clean(data[:adult][:employment][:occupation]), 
      p5_employer: clean(data[:adult][:employment][:employer])
    }
  end
  
  def mailing_address
    address = if(data[:adult].has_key?(:address))
                parse_address(data[:adult][:address])
              elsif(data.has_key?(:address))
                parse_address(data[:address])
              end

    {
      p5_mailing_address: clean(address[:street]), 
      p5_city: clean(address[:city]), 
      p5_state: clean(address[:state]), 
      p5_zip_code: clean(address[:zip]), 
      p5_country: clean('US')
    }
  end
  
  def full_name(page)
    name_values = parse_name(data[:adult][:full_name])
    attrs = {
      "#{page}_first_name".to_sym => clean(name_values[:first]), 
      "#{page}_middle_name".to_sym => clean(name_values[:middle]), 
      "#{page}_last_name".to_sym => clean(name_values[:last]), 
      "#{page}_name_suffix".to_sym => clean(name_values[:suffix])
    }

    attrs
  end
  
  def drivers_license
    info = data[:adult][:drivers_license]
    {
      p5_drivers_license_number: clean(info[:id]), 
      p5_dl_state: clean(info[:state])
    }
  end
  
  def registration_fee
    {
      p5_registration_fee_cents: clean('00'), 
      p5_registration_fee_dollars: clean('12')
    }
  end
  
  def position_code_description
    upc = data[:adult][:position][:code]
    description = (data[:adult][:position][:description] and data[:adult][:position][:description].length > 0) ? data[:adult][:position][:description] : unit_position_codes[upc.to_sym]
    {
      p5_position_code: clean(upc), 
      p5_position_description: clean(description)
    }
  end
  
  def additional_info_value(bool, values=nil)
    if(values)
      (bool) ? values[:true] : values[:false]
    else
      (bool) ? 'Yes' : '2'
    end
  end
  
  def additional_info
    a_info = {
      p5_info_alcohol_desc: data[:adult][:background][:additional_information][:alcohol_abuse], 
      p5_info_child_abuse_desc: data[:adult][:background][:additional_information][:child_abuse],
      p5_info_conduct_or_behavior_desc: data[:adult][:background][:additional_information][:removed_for_personal_conduct],
      p5_info_criminal_offense_desc: data[:adult][:background][:additional_information][:arrested],
      p5_info_drivers_license_desc: data[:adult][:background][:additional_information][:drivers_license_suspend],
      p5_info_suitability_desc: data[:adult][:background][:additional_information][:unsuitable_to_work_with_youth],
    }

    {
      p5_info_alcohol: additional_info_value(a_info[:p5_info_alcohol_desc] && a_info[:p5_info_alcohol_desc].length > 0), 
      p5_info_child_abuse: additional_info_value(a_info[:p5_info_child_abuse_desc] && a_info[:p5_info_child_abuse_desc].length > 0), 
      p5_info_conduct_or_behavior: additional_info_value(a_info[:p5_info_conduct_or_behavior_desc] && a_info[:p5_info_conduct_or_behavior_desc].length > 0, {true: 'Yes', false: 'No'}), 
      p5_info_criminal_offense: additional_info_value(a_info[:p5_info_criminal_offense_desc] && a_info[:p5_info_criminal_offense_desc].length > 0), 
      p5_info_drivers_license: additional_info_value(a_info[:p5_info_drivers_license_desc] && a_info[:p5_info_drivers_license_desc].length > 0), 
      p5_info_suitability: additional_info_value(a_info[:p5_info_suitability_desc] && a_info[:p5_info_suitability_desc].length > 0)
    }.merge(a_info)
  end
  
  def dob
    date = parse_date(data[:adult][:dob])
    
    {
      p5_dob_day: clean(date[:day]), 
      p5_dob_month: clean(date[:month]), 
      p5_dob_year: clean(date[:year])
    }
  end
  
  def phone(type)
    phone_number = if(type == :home)
                     if(data[:adult].has_key?(:phone))
                       parse_phone(data[:adult][:phone])
                     elsif(data.has_key?(:phone))
                       parse_phone(data[:phone])
                     end
                   elsif(type == :cell)
                     parse_phone(data[:adult][:phone_cell])
                   elsif(type == :business)
                     parse_phone(data[:adult][:employment][:phone])
                   end

    if(type == :business)
      {
        "p5_phone_#{type}_area_code".to_sym => clean(phone_number[:area_code]), 
        "p5_phone_#{type}_prefix".to_sym => clean(phone_number[:prefix]), 
        "p5_phone_#{type}_suffix".to_sym => clean(phone_number[:suffix]), 
        "p5_phone_#{type}_extension".to_sym => clean(phone_number[:extension])
      }
    else
      {
        "p5_phone_#{type}_area_code".to_sym => clean(phone_number[:area_code]), 
        "p5_phone_#{type}_prefix".to_sym => clean(phone_number[:prefix]), 
        "p5_phone_#{type}_suffix".to_sym => clean(phone_number[:suffix])
      }
    end
  end

# p5_bg_01_position
# p5_bg_01_year
# p5_bg_02_council
# p5_bg_02_position
# p5_bg_02_year
# p5_bg_03_council
# p5_bg_03_position
# p5_bg_03_year
  
# {name: 'rechartering rep', council: "Rio del Oro", year: 2014}, 

  def positions
    collection = {}
    data[:adult][:background][:positions].each.with_index do |position_entry, i|
      collection.merge!(position(position_entry, (i+1)))
    end
    collection
  end

  def position(entry, index)
    {
      "p5_bg_#{index.to_s.rjust(2, '0')}_position".to_sym => clean(entry[:name]), 
      "p5_bg_#{index.to_s.rjust(2, '0')}_council".to_sym => clean(entry[:council]), 
      "p5_bg_#{index.to_s.rjust(2, '0')}_year".to_sym => clean(entry[:year])
    }
  end
  
  def references
    collection = {}
    data[:adult][:background][:references].each.with_index do |reference_entry, i|
      collection.merge!(reference(reference_entry, (i+1)))
    end
    collection
  end

  def reference(entry, index)
    phone_number = parse_phone(entry[:phone])
    
    phone_main = "#{phone_number[:prefix]}-#{phone_number[:suffix]}"
    
    {
      "p5_reference_#{index.to_s.rjust(2, '0')}_name".to_sym => clean(entry[:name]), 
      "p5_reference_#{index.to_s.rjust(2, '0')}_phone_area_code".to_sym => clean(phone_number[:area_code]),
      "p5_reference_#{index.to_s.rjust(2, '0')}_phone_main".to_sym => clean(phone_main)
    }
  end
  
  def residences
    residence(data[:adult][:background][:previous_residences][0], 1).merge(
      residence(data[:adult][:background][:previous_residences][1], 2)
    )
  end
  
  def residence(line, index)
    address = parse_address(line)
    
    {
      "p5_residence_#{index.to_s.rjust(2, '0')}_city".to_sym => clean(address[:city]), 
      "p5_residence_#{index.to_s.rjust(2, '0')}_state".to_sym => clean(address[:state])
    }
  end

  def email
    info = data[:adult][:email] or data[:adult][:employment][:email]

    type = if(data[:adult][:email].nil? == false)
      :home
    elsif(data[:adult][:employment][:email].nil? == false)
      :work
    else
      nil
    end
    
    email_info = parse_email(info)
    {
      # email: "dcvezzani@gmail.com", 
      p5_email_type: type,
      p5_email_username: clean(email_info[:username]), 
      p5_email_domain: clean(email_info[:domain])
    }
  end

  def eagle_scout
    raw_date = data[:adult][:eagle_scout]

    if(raw_date and raw_date.length > 0)
      date = parse_date(raw_date)
      
      {
        p5_eagle_earned_day: clean(date[:day]), 
        p5_eagle_earned_month: clean(date[:month]), 
        p5_eagle_earned_year: clean(date[:year]), 
        p5_eagle_scout_status: clean('yes')
      }
    else
      {}
    end
  end

  def business_address
    address = parse_address(data[:adult][:employment][:address])
    {
      p5_business_address: clean(address[:street]), 
      p5_business_city: clean(address[:city]), 
      p5_business_state: clean(address[:state]), 
      p5_business_zip_code: clean(address[:zip]), 
      p5_business_country: clean('US')
    }
  end
  
  def prepare(unit_type)
    todays_date = Time.now
    unit_no = '0092'

# p5_alignment_test
# p5_boys_life_fee_cents
# p5_boys_life_fee_dollars
#
# p5_applicant_date: todays_date, 
# p5_chartered_org_representative_date
# p5_scout_exec_signature_date
# p5_unit_committee_chair_date
#
# p5_ssn_001
# p5_ssn_002
# p5_ssn_003
#
# p5_council_position
# p5_district_position
    # p5_boys_life_subscription: false | home
    # p5_info_alcohol: Yes | 2
    # p5_eagle_scout_status: 'No', 

    attrs = {
      p5_info_alcohol: 2,
      p5_info_child_abuse: 2,
      p5_info_conduct_or_behavior: 2,
      p5_info_criminal_offense: 2,
      p5_info_drivers_license: 2,
      p5_info_suitability: 2,
      p5_eagle_scout_status: 'No', 
      p5_boys_life_subscription: false, 
      p4_date: todays_date.strftime("%Y-%m-%d"), 
      p4_request_free_copy: false,
      p4_unit_no: unit_no, 
      p5_term_in_months: 12
    }.merge({
      p5_adult_ethnicity: data[:adult][:ethnicity], 
      p5_adult_gender: data[:adult][:gender], 
      p5_bg_01_council: data[:council], 
      p5_leader_status: ((data[:adult][:previous_scouting_experience].nil?) ? 'new' : 'former'), 
      p5_unit_number: unit_no, 
      p5_unity_type: unit_type
    }).merge({
      p5_memberships: data[:adult][:background][:current_memberships], 
      p5_youth_experience: data[:adult][:background][:youth_experience]
    }).merge(
      expiration_date(todays_date)
    ).merge(
      employment
    ).merge(
      mailing_address
    ).merge(
      full_name(:p5)
    ).merge(
      drivers_license
    ).merge(
      registration_fee
    ).merge(
      residences
    ).merge(
      position_code_description
    ).merge(
      phone(:home)
    ).merge(
      phone(:cell)
    ).merge(
      phone(:business)
    ).merge(
      dob
    ).merge(
      additional_info
    ).merge(
      email
    ).merge(
      full_name(:p4)
    ).merge(
      eagle_scout
    ).merge(
      business_address
    ).merge(
      references
    ).merge(
      positions
    ).merge({
#       # }).merge({
#   # p5_certificate_attached
#   # p5_transfer_council_number
#   # p5_transfer_unit_number
#   # p5_transfer_unit_type
#     }).merge({
    })

# require 'byebug'
# debugger
# x=2-1
    attrs = attrs.merge(file_label(unit_type))
    attrs
  end
  
end
