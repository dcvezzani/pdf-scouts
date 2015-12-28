require 'csv'
require 'yaml'
require 'byebug'

=begin
irb

load '/Users/davidvezzani/Documents/journal/scm/pdf-scouts/collect_recharter_data.rb'
CollectRecharterData.new.generate
=end

class CollectRecharterData
  attr_reader :home, :unit_position_codes, :csv_file, :families, :csv, :data

  def initialize
    @home = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'
    @unit_position_codes = YAML.load_file("#{home}/unit_position_codes.yml")
    @csv_file = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts/rechartering-work.csv'
  end

  def generate
    body = IO.read(csv_file)
    @csv = CSV.new(body, headers: true)

    @data = general
    @families = families_reduce

    families.each do |family_name, mdata|
      fdata = family(mdata)
      debugger
      fdata[:adults] = adults(mdata)
      fdata[:youth] = youths(mdata)
      data[:families][family_name] = fdata
    end

    data
  end

  def general
    {
      unit_number: 92, 
      council: "Rio del Oro", 
      unit_types: %w{troop}, 
      boys_life_subscription: true, 
      families: {}
    }
  end

  def adult(member)
      adata = {
        full_name: member["name"], 
        relationship: member["relationship"], 
        email: member["email"], 
        phone_cell: '', 
        dob: member["bday"], 
        ethnicity: member["ethnicity"], 
        gender: member["gender"], 
        previous_scouting_experience: member["previous_experience"], 
        eagle_scout: member["eagle_scout"], 
        boys_life_subscription: false
      }

      occu = (member["occupation"] or '').split(/;/)
      if(occu.length == 4)
      adata[:employment] = {
        occupation: occu[0], 
        employer: occu[1], 
        phone: occu[2], 
        address: occu[3]
      }
      end

      adata[:position] = {
        code: member["position_code"], 
        description: (member["position_description"] or unit_position_codes[member["position_code"].to_sym])
      }

      adata[:background] = {
        positions: [], 
        previous_residences: [], 
        current_memberships: [], 
        references: [], 
        additional_information: []
      }
      
      lines = member["background_positions"].to_s.split(/;\s*/)
      lines.each do |line|
        bg_pos = line.to_s.split(/,\s*/)

        if(occu.length == 3)
        adata[:background][:positions] << {
          name: bg_pos[0], 
          council: bg_pos[1], 
          year: bg_pos[2]
        }
        end
      end

      adata[:background][:youth_experience] = member["youth_experience"]
      adata[:background][:current_memberships] = member["memberships"]
      
      lines = member["residences"].to_s.split(/;\s*/)
      lines.each do |line|
        adata[:background][:residences] = line
      end
      

      lines = member["references"].to_s.split(/;\s*/)
      lines.each do |line|
        reference = line.to_s.split(/,\s*/)

        if(reference.length == 2)
        adata[:background][:references] << {
          name: reference[0], 
          phone: reference[1]
        }
        end
      end

      unless(member["additional_information"].nil?)
        if(member["additional_information"] == "FALSE")
          adata[:background][:additional_information] = {
            removed_for_personal_conduct: false, 
            alcohol_abuse: false, 
            arrested: false, 
            drivers_license_suspend: false, 
            child_abuse: false, 
            unsuitable_to_work_with_youth: false
          }
        end
      end

      adata
  end

  def adults(mdata)
    list = []
    mdata.each do |md|
      next if md["person"] != "Adult"
      list << adult(md)
    end
    list
  end

  def youth(member)
      ydata = {
        full_name: member["name"], 
        dob: DateTime.strptime(member["bday"], "%d %b %y").strftime("%Y-%m-%d"), 
        grade: member["grade"], 
        ethnicity: member["ethnicity"], 
        school: member["school"], 
        gender: member["gender"], 
        previous_status: member["previous_status"]
      }

      ydata[:unit_types] = []
      %w{troop team crew cub webelos}.each do |unit_type|
        ydata[:unit_types] << unit_type if(member[unit_type] == "TRUE")
      end
      
      ydata
  end

  def youths(mdata)
    list = []
    mdata.each do |md|
      next if md["person"] != "Youth"
      list << youth(md)
    end
    list
  end

  def family(mdata)
    {
      address: mdata.first["address"], 
      phone: mdata.first["phone"], 
      scouts: [], 
      adults: []
    }
  end

  def families_reduce
    lines = csv.to_a

    to_print = []

    lines.each do |line|
    to_print << line.to_h if line["membership_num"] and line["membership_num"].downcase.strip == 'new'
    end

    families = to_print.map{|x| x["family"]}.uniq
    # => ["Miles", "Conn", "Hanson", "Segales", "Van Horn", "Charlson", "North", "Durrant", "Szelestey", "Larios", "Roy", "Pickett", "Laloata"]
    families = %w{Miles}

    to_print = {}

    families.each do |family|
      lines.each do |line|
        # debugger if line["family"] == family
        to_print[family] = [] if to_print[family].nil?
        to_print[family] << line.to_h if line["family"] == family
      end
    end

    to_print
  end
  
end


