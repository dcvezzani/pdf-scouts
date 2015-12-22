require "minitest/autorun"
require_relative "../collect_recharter_data"
require 'byebug'

=begin
ruby -Ilib:test test/collect_recharter_data_test.rb

  def initialize
  def generate
  def general
  def adult(member)
  def adults(mdata)
  def youth(mdata)
  def youths(mdata)
  def family(mdata)
  def families_reduce
=end

describe CollectRecharterData do
  before do
    @crdata = CollectRecharterData.new

@adult = {"name"=>"Diane Conn", "a001"=>nil, "a002"=>nil, "membership_num"=>"new", "family"=>"Conn", "leader"=>nil, "phone"=>"209-338-7588", "bday"=>"5 Dec 79", "email"=>"diane125@msn.com", "additional_information"=>nil, "occupation"=>nil, "position_code"=>"MC", "position_description"=>nil, "memberships"=>nil, "references"=>nil, "background_positions"=>nil, "youth experience"=>nil, "residences"=>nil, "eagle_scout"=>nil, "previous_experience"=>"new", "relationship"=>nil, "ethnicity"=>"wht_cauca", "school"=>nil, "previous_status"=>nil, "gender"=>"female", "age"=>nil, "grade"=>nil, "address"=>"2060 4th St", "person"=>"Adult", "committee member"=>"FALSE", "troop"=>"TRUE", "team"=>"FALSE", "crew"=>"FALSE", "pack"=>"FALSE", "webelos"=>"FALSE"}

@youth = {"name"=>"Andrew Conn", "a001"=>nil, "a002"=>"x", "membership_num"=>"123549712", "family"=>"Conn", "leader"=>nil, "phone"=>"209-338-7588", "bday"=>"9 Jun 02", "email"=>nil, "additional_information"=>nil, "occupation"=>nil, "position_code"=>nil, "position_description"=>nil, "memberships"=>nil, "references"=>nil, "background_positions"=>nil, "youth experience"=>nil, "residences"=>nil, "eagle_scout"=>nil, "previous_experience"=>nil, "relationship"=>nil, "ethnicity"=>"wht_cauca", "school"=>nil, "previous_status"=>"troop", "gender"=>"male", "age"=>"13", "grade"=>"8", "address"=>"2060 4th St", "person"=>"Youth", "committee member"=>"FALSE", "troop"=>"TRUE", "team"=>"FALSE", "crew"=>"FALSE", "pack"=>"FALSE", "webelos"=>"FALSE"}

@vezzani = [{"name"=>"David Vezzani", "a001"=>nil, "a002"=>nil, "membership_num"=>"128401851", "family"=>"Vezzani", "leader"=>"committee member, 2.Chartered Organization Rep.", "phone"=>"209-756-9688", "bday"=>"19 Sep 72", "email"=>"dcvezzani@gmail.com", "additional_information"=>"FALSE", "occupation"=>"s/w engineer; Crystal Commerce; 209-756-9688; 220th St SW, Mountlake Terrace, WA 98043", "position_code"=>"MC", "position_description"=>"rechartering representative", "memberships"=>"Church of Jesus Christ of Latter Day Saints", "references"=>"David Tyrrell, (304) 261-4319; David Orr, (304) 707-4042; Stephen Vorhauer, (304) 725-4419", "background_positions"=>"rechartering rep, Rio del Oro, 2014; troop committee chair, Rio del Oro, 2013", "youth experience"=>"church youth leader, instructor, scouts", "residences"=>"5922 N. Krotik Ct., Atwater, CA 95301; 364 Sawgrass Drive, Charles Town, WV 25414", "eagle_scout"=>nil, "previous_experience"=>"former", "relationship"=>nil, "ethnicity"=>"wht_cauca", "school"=>nil, "previous_status"=>nil, "gender"=>"male", "age"=>nil, "grade"=>nil, "address"=>"5922 N Krotik Ct", "person"=>"Adult", "committee member"=>"TRUE", "troop"=>"TRUE", "team"=>"TRUE", "crew"=>"TRUE", "pack"=>"TRUE", "webelos"=>"FALSE"}, {"name"=>"Jordan Vezzani", "a001"=>"x", "a002"=>"x", "membership_num"=>"127451919", "family"=>"Vezzani", "leader"=>"change: add to crew, remove from team", "phone"=>"209-756-9688", "bday"=>"13 Nov 98", "email"=>"jordanthemormon14@gmail.com", "additional_information"=>nil, "occupation"=>nil, "position_code"=>nil, "position_description"=>nil, "memberships"=>nil, "references"=>nil, "background_positions"=>nil, "youth experience"=>nil, "residences"=>nil, "eagle_scout"=>nil, "previous_experience"=>nil, "relationship"=>nil, "ethnicity"=>"wht_cauca", "school"=>"Atwater High", "previous_status"=>"team", "gender"=>"male", "age"=>"17", "grade"=>"11", "address"=>"5922 N Krotik Ct", "person"=>"Youth", "committee member"=>"FALSE", "troop"=>"TRUE", "team"=>"FALSE", "crew"=>"TRUE", "pack"=>"FALSE", "webelos"=>"FALSE"}, {"name"=>"Matthew Vezzani", "a001"=>nil, "a002"=>"x", "membership_num"=>"127451898", "family"=>"Vezzani", "leader"=>nil, "phone"=>"209-676-4097", "bday"=>"22 Nov 03", "email"=>nil, "additional_information"=>nil, "occupation"=>nil, "position_code"=>nil, "position_description"=>nil, "memberships"=>nil, "references"=>nil, "background_positions"=>nil, "youth experience"=>nil, "residences"=>nil, "eagle_scout"=>nil, "previous_experience"=>nil, "relationship"=>nil, "ethnicity"=>"wht_cauca", "school"=>"Hickman", "previous_status"=>"webelos", "gender"=>"male", "age"=>"12", "grade"=>"6", "address"=>"5922 N Krotik Ct", "person"=>"Youth", "committee member"=>"FALSE", "troop"=>"TRUE", "team"=>"FALSE", "crew"=>"FALSE", "pack"=>"FALSE", "webelos"=>"FALSE"}]
  end

  describe "#general" do
    it "generate the basic framework" do
      @crdata.general.must_be_kind_of Hash
    end
  end
  
  describe "#youth" do
    it "generate data for youth" do
      ydata = @crdata.youth(@youth)
      # [:full_name, :dob, :grade, :ethnicity, :school, :gender, :previous_status, :unit_types]
      # ydata.keys.must_include 'asdf'
      ydata.keys.length.must_equal 8
      ydata[:unit_types].must_equal ["troop"]
    end
  end
  
  describe "#adult" do
    it "generate data for adult" do
      adata = @crdata.adult(@adult)
      # [:full_name, :relationship, :email, :phone_cell, :dob, :ethnicity, :gender, :previous_scouting_experience, :eagle_scout, :boys_life_subscription, :position, :background]
      # adata.keys.must_include 'asdf'
      adata.keys.length.must_equal 12

      # [:positions, :previous_residences, :current_memberships, :references, :additional_information, :youth_experience]
      # adata[:background].keys.must_include "asdf"
      adata[:background].length.must_equal 6
      adata[:gender].must_equal 'female'
    end
  end
  
end
