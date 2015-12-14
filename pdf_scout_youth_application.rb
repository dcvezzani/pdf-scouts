require 'bundler/setup'
require_relative 'pdf_scout_application'

=begin
irb

home = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'

require 'yaml'
data = YAML.load_file("#{home}/data.yml")
upc = YAML.load_file("#{home}/unit_position_codes.yml")

load "#{home}/pdf_scout_application.rb"
load "#{home}/pdf_scout_youth_application.rb"
family_data = (data[:families]["Vezzani"]).merge(data.select{|k,v| [:unit_number, :council, :unit_types, :boys_life_subscription].include?(k)})
youth = PdfScoutYouthApplication.new(family_data, 1, :troop, upc)

attrs = youth.prepare(:troop)
File.open("#{home}/chk-youth.txt", "w"){|f| f.write attrs.inspect
  f.write "\n\n"
  f.write attrs.keys.map(&:to_s).sort.map{|k| "#{k}: #{attrs[k.to_sym]}"}.join("\n")
}
# File.open("#{home}/youth-fields.txt", "w"){|f| f.write youth.fields(:youth).sort.join("\n") }

youth.print(:youth, attrs, "#{home}/youth.#{attrs[:file_label]}.unc.filled.pdf")

`open #{home}/youth.#{attrs[:file_label]}.unc.filled.pdf`
=end

class PdfScoutYouthApplication < PdfScoutApplication

  def initialize(data, index, unit_type, unit_position_codes)
    super(data, unit_position_codes)
    data[:youth] = data[:scouts][index]
    data[:youth][:unit_type] = unit_type
  end

  # def full_name(page)
  #   name_values = parse_name(data[:adult][:full_name])
  #   {
  #     "#{page}_first_name".to_sym => clean(name_values[:first]), 
  #     "#{page}_middle_name".to_sym => clean(name_values[:middle]), 
  #     "#{page}_last_name".to_sym => clean(name_values[:last]), 
  #     "#{page}_name_suffix".to_sym => clean(name_values[:suffix])
  #   }
  # end

  def file_label(unit_type)
    # return file_label unless file_label.nil?
    name_values = parse_name(data[:youth][:full_name])
    {file_label: "#{name_values[:last]} #{name_values[:first]} #{name_values[:middle]} #{name_values[:suffix]} #{unit_type}".strip.downcase.gsub(/\W+/, '-')}
    
  end

  def boys_life
    boys_life_subscription_value = if(data[:youth].has_key?(:boys_life_subscription))
      data[:youth][:boys_life_subscription]
    elsif(data.has_key?(:boys_life_subscription))
      data[:boys_life_subscription]
    else
      false
    end

    if(boys_life_subscription_value)
      {
        p5_boys_life_fee_dollar: '12',
        p5_boys_life_fee_cents: '00', 
        p5_boys_life_subscription: 'Yes'
      }
    else
      {
        p5_boys_life_subscription: 'No'
      }
    end
  end

  def arrow_of_light
    arrow_of_light_value = (data[:youth][:arrow_of_light]) ? 'Yes' : false
    # puts ">>> #{arrow_of_light_value}"
    {
      p5_arrow_of_light: arrow_of_light_value
    }
  end

  def lone_scout
    if(data[:youth][:lone_scout])
      if(
          data[:youth][:unit_type] == :tiger or 
          data[:youth][:unit_type] == :cub or 
          data[:youth][:unit_type] == :webelos
        )
        {
          p5_lone_scout: :cub
        }
      else
        {
          p5_lone_scout: :boy
        }
      end
    else
      {}
    end
  end
  
  def unit_type_value(unit_type)
    if(
        unit_type == :tiger or 
        unit_type == :cub or 
        unit_type== :webelos
        # data[:youth][:unit_types].include?(:tiger) or
        # data[:youth][:unit_types].include?(:cub) or
        # data[:youth][:unit_types].include?(:webelos)
      )
      {
        p5_pack_type: unit_type, 
        p5_unit_type: :pack
      }
    else
      {
        p5_unit_type: unit_type
      }
    end
  end
  
  def dob(person)
    if(person == :parent)
      date = parse_date(data[:adult][:dob])
      
      {
        p5_parent_birth_date_day: clean(date[:day]), 
        p5_parent_birth_date_month: clean(date[:month]), 
        p5_parent_birth_date_year: clean(date[:year])
      }
    elsif(person == :scout)
      date = parse_date(data[:youth][:dob])
      
      {
        p5_scout_birth_date_day: clean(date[:day]), 
        p5_scout_birth_date_month: clean(date[:month]), 
        p5_scout_birth_date_year: clean(date[:year])
      }
    end
  end

  def phone(person, type)

    person_label = if(person == :parent)
                     :adult
                   elsif(person == :scout)
                     :youth
                   end
    phone_label = if(type == :home)
                    :phone
                  elsif(type == :cell)
                    :phone_cell
                  elsif(type == :business)
                    [:employment, :phone]
                  end

    phone_number = if(phone_label.is_a?(Array))
      parse_phone(data[person_label][phone_label[0]][phone_label[1]])
    elsif(data[person_label].has_key?(phone_label))
      parse_phone(data[person_label][phone_label])
    elsif(data[:phone])
      parse_phone(data[:phone])
    end

    if(type == :business)
      {
        "p5_#{person}_phone_#{type}_area_code".to_sym => clean(phone_number[:area_code]), 
        "p5_#{person}_phone_#{type}_middle_three".to_sym => clean(phone_number[:prefix]), 
        "p5_#{person}_phone_#{type}_last_four".to_sym => clean(phone_number[:suffix]), 
        "p5_#{person}_phone_#{type}_extension".to_sym => clean(phone_number[:extension])
      }
    else
      {
        "p5_#{person}_phone_#{type}_area_code".to_sym => clean(phone_number[:area_code]), 
        "p5_#{person}_phone_#{type}_middle_three".to_sym => clean(phone_number[:prefix]), 
        "p5_#{person}_phone_#{type}_last_four".to_sym => clean(phone_number[:suffix])
      }
    end
  end

  def address(person, person_label=nil)
    
    address = if(person == :parent)
                if(data[:adult].has_key?(:address))
                  parse_address(data[:adult][:address])
                elsif(data.has_key?(:address))
                  parse_address(data[:address])
                end
                            
              elsif(person == :scout)
                if(data[:youth].has_key?(:address))
                  parse_address(data[:youth][:address])
                elsif(data.has_key?(:address))
                  parse_address(data[:address])
                end
              end

    person_label = (person_label or person)
   {
      "p5_#{person_label}_mailing_address".to_sym => clean(address[:street]),
      "p5_#{person_label}_city".to_sym => clean(address[:city]),
      "p5_#{person_label}_state".to_sym => clean(address[:state]),
      "p5_#{person_label}_zip_code".to_sym => clean(address[:zip]),
      "p5_#{person_label}_country".to_sym => 'US'
    }
  end
  
  def email
    info = data[:adult][:email] or data[:adult][:employment][:email]
    email_info = parse_email(info)

    {
      # email: "dcvezzani@gmail.com", 
      p5_parent_email_user: clean(email_info[:username]), 
      p5_parent_email_domain: clean(email_info[:domain])
    }
  end
  
  def full_name(person)
    name_values = if(person == :parent)
                    parse_name(data[:adult][:full_name])
                  elsif(person == :scout)
                    parse_name(data[:youth][:full_name])
                  end

    attrs = {
      "p5_#{person}_first_name".to_sym => clean(name_values[:first]), 
      "p5_#{person}_middle_name".to_sym => clean(name_values[:middle]), 
      "p5_#{person}_last_name".to_sym => clean(name_values[:last]), 
      "p5_#{person}_suffix".to_sym => clean(name_values[:suffix])
    }

    attrs.merge!({
      "p3_#{person}_full_name".to_sym => "#{name_values[:first]} #{name_values[:middle]} #{name_values[:last]} #{name_values[:suffix]}".strip, 
    })
    
    attrs
  end
  
  def employment
    {
      p5_parent_occupation: clean(data[:adult][:employment][:occupation]), 
      p5_parent_employer: clean(data[:adult][:employment][:employer])
    }
  end
  
  def registration_fee
    {
      p5_registration_fee_cents: clean('00'), 
      p5_registration_fee_dollars: clean('12')
    }
  end
  
  def status
    scout_status = if(data[:youth].has_key?(:status))
                     data[:youth][:status]
                   else
                     :scout
                   end
    {
      p5_scout_status: scout_status
    }
  end
  
  def grade
    {
      p5_scout_grade: clean(data[:youth][:grade].to_s.rjust(2, '0'))
    }
  end
  
  def signed_date(date_value)
    date = parse_date(date_value)
    
    {
      p5_unit_leader_signed_date_day: clean(date[:day]), 
      p5_unit_leader_signed_date_month: clean(date[:month]), 
      p5_unit_leader_signed_date_year: clean(date[:year])
    }
  end
  
  def adult_relationship
    relationship_value = data[:adult][:relationship]

    if(%w{parent guardian grandparent}.include?(relationship_value))
      {
        p5_parent_relationship: relationship_value, 
        p5_parent_relationship_other_description: '' 
      }
    else
      {
        p5_parent_relationship: 'other', 
        p5_parent_relationship_other_description: clean(relationship_value)
      }
    end
  end
  
  def prepare(unit_type)
    todays_date = Time.now
    tds = todays_date.strftime("%Y-%m-%d")
    unit_no = '0092'
  
    attrs = {
      p3_registration_date: tds, 
      p3_unit_number: unit_no, 
      p5_adult_ethnicity: data[:adult][:ethnicity], 
      p5_scout_ethnicity: data[:youth][:ethnicity],
      p5_parent_gender: data[:adult][:gender], 
      p5_scout_gender: data[:youth][:gender],
      p5_scout_school: clean(data[:youth][:school]),
      p5_unit_number: unit_no
    }.merge(
      arrow_of_light
    ).merge(
      grade
    ).merge(
      boys_life
    ).merge(
      lone_scout
    ).merge(
      dob(:scout)
    ).merge(
      dob(:parent)
    ).merge(
      phone(:scout, :home)
    ).merge(
      phone(:parent, :home)
    ).merge(
      phone(:parent, :business)
    ).merge(
      phone(:parent, :cell)
    ).merge(
      unit_type_value(unit_type)
    ).merge(
      address(:scout)
    ).merge(
      email
    ).merge(
      full_name(:parent)
    ).merge(
      full_name(:scout)
    ).merge(
      registration_fee
    ).merge(
      status
    ).merge(
      signed_date(tds)
    ).merge(
      employment
    ).merge(
      adult_relationship
    ).merge({
      p5_parent_previous_scouting_experience: clean(data[:adult][:previous_scouting_experience])
      # p5_parent_tap_not_same_address: clean(data[:asdf]),
      # p5_parent_tiger_adult_partner: clean(data[:asdf]),
    }).merge({
      p5_transfer_application: clean(data[:asdf]),
      p5_transfer_council_number: clean(data[:asdf]),
      p5_transfer_membership_number: clean(data[:asdf]),
      p5_transfer_unit_number: clean(data[:asdf]),
      p5_transfer_unit_type: clean(data[:asdf])
    })

    if(data[:adult].has_key?(:address))
      attrs.merge!(
        address(:parent)
      )
    else
      attrs = attrs.merge({
        p5_parent_same_address: 'Yes'
      }).merge(
        address(:scout, :parent)
      )
    end

    attrs = attrs.merge(file_label(unit_type))

    attrs
  end
end
