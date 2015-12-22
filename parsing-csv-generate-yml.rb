require 'csv'

home = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts'
unit_position_codes = YAML.load_file("#{home}/unit_position_codes.yml")

csv_file = '/Users/davidvezzani/Documents/journal/scm/pdf-scouts/rechartering-work.csv'
body = IO.read(csv_file)
csv = CSV.new(body, headers: true)

lines = csv.to_a

to_print = []

lines.each do |line|
to_print << line.to_h if line["membership_num"] and line["membership_num"].downcase.strip == 'new'
end

families = to_print.map{|x| x["family"]}.uniq
#=> ["Miles", "Conn", "Hanson", "Segales", "Van Horn", "Charlson", "North", "Durrant", "Szelestey", "Larios", "Roy", "Pickett", "Laloata", "Moore"]

families << "Vezzani"
to_print = {}

families.each do |family|
  lines.each do |line|
    to_print[family] = [] if to_print[family].nil?
    to_print[family] << line.to_h if line["family"] == family
  end
end

data = {
  unit_number: 92, 
  council: "Rio del Oro", 
  unit_types: %w{troop}, 
  boys_life_subscription: true, 
  families: {}
}

to_print.each do |family, mdata|
  fdata = {
    address: mdata.first[:address], 
    phone: mdata.first[:phone], 
    scouts: [], 
    adults: []
  }

  mdata.each do |member|
    case(member[:person]) do
    when "Adult"
      adult = {
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
      adult[:employment] = {
        occupation: occu[0], 
        employer: occu[1], 
        phone: occu[2], 
        address: occu[3]
      }
      end

      adult[:position] = {
        code: member["position_code"], 
        description: member["position_description"] or unit_position_codes[member["position_code"].to_sym]
      }

      adult[:background] = {
        positions: [], 
        previous_residences: [], 
        current_memberships: [], 
        references: [], 
        additional_information: []
      }
      
      lines = member["background_positions"].split(/;\s*/)
      lines.each do |line|
        bg_pos = line.to_s.split(/,\s*/)

        if(occu.length == 3)
        adult[:background][:positions] << {
          :name: bg_pos[0]
          :council: bg_pos[1]
          :year: bg_pos[2]
        }
        end
      end

      adult[:background][:youth_experience] = member["youth_experience"]
      adult[:background][:current_memberships] = member["memberships"]
      
      lines = member["residences"].to_s.split(/;\s*/)
      lines.each do |line|
        adult[:background][:residences] = line
      end
      

      lines = member["references"].split(/;\s*/)
      lines.each do |line|
        reference = line.to_s.split(/,\s*/)

        if(reference.length == 2)
        adult[:background][:references] << {
          name: reference[0], 
          phone: reference[1]
        }
        end
      end

      unless(member["additional_information"].nil?)
        if(member["additional_information"] == "false")
          adult[:background][:additional_information] = {
            :removed_for_personal_conduct: false, 
            :alcohol_abuse: false, 
            :arrested: false, 
            :drivers_license_suspend: false, 
            :child_abuse: false, 
            :unsuitable_to_work_with_youth: false
          }
        end
      end
  
      fdata[:adults] << adult

    when "Youth"
      youth = {
        full_name: member["name"], 
        dob: Time.strptime(member["bday"], "%d %b %y").strftime("%Y-%m-%d"), 

        grade: member["grade"]
        ethnicity: member["ethnicity"]
        school: member["school"]
        gender: member["gender"]
        previous_status: member["previous_status"]
      }

      youth[:unit_types] = []
      %w{troop team crew cub webelos}.each do |unit_type|
        youth[:unit_types] << unit_type if member[unit_type]
      end
      
      fdata[:youth] << youth
    end
  end

  data[:families][family] = fdata
end



puts to_print["Conn"]
{"a001"=>nil, "a002"=>nil, "membership_num"=>"new", "family"=>"Conn", "name"=>"Diane Conn", "leader"=>nil, "phone"=>"209-338-7588", "bday"=>"5 Dec 79", "email"=>"diane125@msn.com", "age"=>nil, "grade"=>nil, "address"=>"2060 4th St", "person"=>"Adult", "committee member"=>"FALSE", "troop"=>"TRUE", "team"=>"FALSE", "crew"=>"FALSE", "pack"=>"FALSE", "webelos"=>"FALSE"}
{"a001"=>nil, "a002"=>"x", "membership_num"=>"123549712", "family"=>"Conn", "name"=>"Andrew Conn", "leader"=>nil, "phone"=>"209-338-7588", "bday"=>"9 Jun 02", "email"=>nil, "age"=>"13", "grade"=>"8", "address"=>"2060 4th St", "person"=>"Youth", "committee member"=>"FALSE", "troop"=>"TRUE", "team"=>"FALSE", "crew"=>"FALSE", "pack"=>"FALSE", "webelos"=>"FALSE"}

to_print["Conn"].select{|m| m["person"] == "Youth"}
Time.strptime("5 Dec 79", "%d %b %y").strftime("%Y-%m-%d")

  "Vezzani":
    :address: to_print[family]["address"]
    :phone: to_print[family]["phone"]


    :scouts:
    to_print["Conn"].select{|m| m["person"] == "Youth"}.each do |youth|

    - :full_name: youth["name"]
      :arrow_of_light: true
      :dob: Time.strptime(youth["bday"], "%d %b %y").strftime("%Y-%m-%d")
      :grade: youth["grade"]
      :ethnicity: youth["ethnicity"]
      :school: youth["school"]
      :gender: youth["gender"]

      :unit_types: << "troop" if youth["troop"]
      :unit_types: << "team" if youth["team"]
      :unit_types: << "crew" if youth["crew"]
      :unit_types: << "cub" if youth["cub"]
      :unit_types: << "webelos" if youth["webelos"]

      :previous_status: youth["previous_status"]
    
    end


    :adults:
    to_print["Conn"].select{|m| m["person"] == "Adult"}.each do |adult|

    - :full_name: adult["name"]
      :relationship: parent
      :email: adult["email"]
      :phone_cell: 
      :dob: adult["bday"]
      :ethnicity: adult["ethnicity"]
      :gender: adult["gender"]
      :previous_scouting_experience: adult["previous_experience"]
      :eagle_scout: adult["eagle_scout"]
      :boys_life_subscription: false
      :drivers_license:
        :id: ''
        :state: CA
      :employment:

        occu = adult["occupation"].split(/;/)

        :occupation: occu[0]
        :employer: occu[1]
        :phone: occu[2]
        :address: occu[3]

      :position:
        :code: adult["position_code"]
        :description: adult["position_description"] or unit_position_codes[adult["position_code"].to_sym]
      :background:
        :positions:

          lines = adult["background_positions"].split(/;\s*/)
          lines.each do |line|
            bg_pos = line.split(/,\s*/)

          - :name: bg_pos[0]
            :council: bg_pos[1]
            :year: bg_pos[2]
          end

        :youth_experience: adult["youth_experience"]
        :previous_residences:

          lines = adult["residences"].split(/;\s*/)
          lines.each do |line|
            - line
          end
          
        :current_memberships: adult["memberships"]
        :references:

          lines = adult["references"].split(/;\s*/)
          lines.each do |line|
            reference = line.split(/,\s*/)
          
            - :name: reference[0]
              :phone: reference[1]
          end

        unless(adult["memberships"].nil?)
        :additional_information:
          :removed_for_personal_conduct: 
          :alcohol_abuse: 
          :arrested: 
          :drivers_license_suspend: 
          :child_abuse: 
          :unsuitable_to_work_with_youth: 
        end

    end
    
