# frozen_string_literal: true

class KanjiStroke
  include Mongoid::Document

  embedded_in :word

  field :stroke_number, type: Integer
  field :stroke_order, type: Integer
  field :stroke_type, type: String
  field :svg_path, type: String
  field :direction, type: String

  validates :stroke_number, presence: true

  def as_json(options = {})
    {
      id: id.to_s,
      stroke_number: stroke_number,
      stroke_order: stroke_order,
      stroke_type: stroke_type,
      svg_path: svg_path,
      direction: direction
    }
  end
end
