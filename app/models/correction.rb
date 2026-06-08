class Correction < ActiveRecord::Base
  scope :edits, -> { where(correction_type: 'edit') }
  scope :merges, -> { where(correction_type: 'merge') }

  def self.record_edit(source_identifier, field, old_value, new_value, editor_name, description = nil)
    create(
      correction_type: 'edit',
      editor: editor_name,
      source_identifier: source_identifier,
      field: field,
      old_value: old_value,
      new_value: new_value,
      description: description || "Changed #{field} from '#{old_value}' to '#{new_value}'",
      timestamp: Time.now
    )
  end

  def self.record_merge(source_ids, canonical_id, merged_into, editor_name, description = nil)
    create(
      correction_type: 'merge',
      editor: editor_name,
      source_ids: source_ids.to_json,
      canonical_id: canonical_id,
      description: description || "Merged #{source_ids.length} records",
      timestamp: Time.now
    )
  end

  def self.audit_log(limit = 100)
    order(timestamp: :desc).limit(limit)
  end

  def self.edits_for_book(source_identifier)
    where(correction_type: 'edit', source_identifier: source_identifier).order(timestamp: :desc)
  end

  def self.undo_edit(edit_id)
    edit = find_by(id: edit_id)
    return false unless edit
    edit.destroy
    true
  end
end
