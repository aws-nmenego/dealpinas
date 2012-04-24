require 'rubygems'
require 'composite_primary_keys'

class Search < ActiveRecord::Base
  def deals
    @deals ||= find_deals
  end
  
  private
  
  def find_deals
    Deal.find(:all, :conditions => conditions)
  end
  
  def keyword_conditions
    ["deals.title LIKE ?", "%#{keywords}%"] unless keywords.blank?
  end
  
  def category_conditions
    ["deals.category_id = ?", category_id] unless category_id.blank?
  end
  
  def conditions
    [conditions_clauses.join(' AND '), *conditions_options]
  end
  
  def conditions_clauses
    conditions_parts.map { |condition| condition.first }
  end
  
  def conditions_options
    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end
  
  def conditions_parts
    private_methods(false).grep(/_conditions$/).map { |m| send(m) }.compact
  end
end