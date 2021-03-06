class Taxon < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
  acts_as_nested_set 

  #belongs_to :taxonomy
  has_many :assigned_layer_taxons
  has_many :layers, :through => :assigned_layer_taxons, :uniq => true

  has_many :assigned_context_taxons
  has_many :geo_contexts, :through => :assigned_context_taxons, :uniq => true

  validates :name, :presence => true
  
  scope :only_themes, lambda {
        
         where({:parent => Taxon.find('themes').id})
    }
  scope :right_order, :order => "lft asc, rgt asc"

  class << self
    include CollectiveIdea::Acts::NestedSet::Helper
    def all_themes_select
      Taxon.find('themes').self_and_descendants.right_order.map{|t| ["#{'-' *t.level}#{t.name}",t.id]}  
      #nested_set_options(themes) {|i| "#{'-' * (i.level - 1)} #{i.name }"}
    end

    def themes_select(selected = nil)
      Taxon.find('themes').descendants.right_order.map{|t| ["#{'-' *(t.level - 1)}#{t.name}",t.id]}  
    end


    def themes
      Taxon.find("themes").children
    end
  end

  def children_layers_length
    descendants.includes(:layers).inject(0) do |n, child|
      n += child.layers.published.length
      n
    end
  end
end
