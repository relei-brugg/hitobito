require 'ostruct'
class GroupExhibit < DisplayCase::Exhibit
  extend Forwardable
  def_delegators :context, :content_tag, :can?

  def self.applicable_to?(object)
    return false if object.class.name == 'ActiveRecord::Relation'
    object.class.name == 'Group' || object.class.base_class.name == 'Group'
  end

  def possible_children
    self.class.possible_children.collect(&:model_name).map do |name|
      link = context.new_group_path(group: { parent_id: self.id, type: name})
      OpenStruct.new(target: link, name: name.human)
    end
  end
  def possible_children_options
    types = self.class.possible_children.collect(&:model_name)
    context.options_from_collection_for_select(types, :to_s, :human)
  end

  def used_attributes(group_specific_attributes)
    group_specific_attributes -= self.class.superior_attributes unless can? :modify_superior, self
    group_specific_attributes.select { |name| self.class.attr_used?(name) }
  end

  def kind_of?(klass)
    klass >= self.class ? true : super
  end

  def inspect
    "Exhibit[#{__getobj__.inspect}]"
  end

  private
  def attrs_for_remote
    url = context.fields_groups_path(group: { parent_id: parent.id })
    url = URI.unescape(url)
    { data: { remote: true, replace: true, url: url }  } 
  end

  def type_as_sym
    type && type.split('::').last.downcase.to_sym
  end

end