require 'json'

class Correction
  def self.corrections_path
    Rails.root.join('db', 'corrections.json')
  end

  def self.load_corrections
    return { 'edits' => [], 'merges' => [] } unless File.exist?(corrections_path)
    JSON.parse(File.read(corrections_path))
  rescue
    { 'edits' => [], 'merges' => [] }
  end

  def self.save_corrections(data)
    File.write(corrections_path, JSON.pretty_generate(data))
  end

  # Record a book edit
  def self.record_edit(source_identifier, field, old_value, new_value, editor_name, description = nil)
    corrections = load_corrections

    edit = {
      'id' => "edit_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
      'type' => 'book_edit',
      'timestamp' => Time.now.iso8601,
      'editor' => editor_name,
      'source_identifier' => source_identifier,
      'field' => field,
      'old_value' => old_value,
      'new_value' => new_value,
      'description' => description || "Changed #{field} from '#{old_value}' to '#{new_value}'"
    }

    corrections['edits'] ||= []
    corrections['edits'] << edit

    save_corrections(corrections)
    edit
  end

  # Record a merge
  def self.record_merge(source_ids, canonical_id, merged_into, editor_name, description = nil)
    corrections = load_corrections

    merge = {
      'id' => "merge_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
      'type' => 'merge',
      'timestamp' => Time.now.iso8601,
      'editor' => editor_name,
      'source_ids' => source_ids,
      'canonical_id' => canonical_id,
      'merged_into' => merged_into,
      'description' => description || "Merged #{source_ids.length} records"
    }

    corrections['merges'] ||= []
    corrections['merges'] << merge

    save_corrections(corrections)
    merge
  end

  # Get all corrections
  def self.all
    load_corrections
  end

  # Apply corrections to books (returns corrected book)
  def self.apply_corrections_to_book(book, source_identifier)
    corrections = load_corrections
    return book unless corrections['edits'].any?

    corrected_book = book.dup

    # Find all edits for this book
    relevant_edits = corrections['edits'].select { |e| e['source_identifier'] == source_identifier }

    relevant_edits.each do |edit|
      field = edit['field']
      new_value = edit['new_value']
      corrected_book[field] = new_value
    end

    corrected_book
  end

  # Get audit log
  def self.audit_log(limit = 100)
    corrections = load_corrections
    all_items = (corrections['edits'] || []) + (corrections['merges'] || [])
    all_items.sort_by { |item| item['timestamp'] }.reverse.first(limit)
  end

  # Get edits for a specific book
  def self.edits_for_book(source_identifier)
    corrections = load_corrections
    (corrections['edits'] || []).select { |e| e['source_identifier'] == source_identifier }
  end

  # Undo an edit
  def self.undo_edit(edit_id)
    corrections = load_corrections
    edit = corrections['edits'].find { |e| e['id'] == edit_id }
    return false unless edit

    corrections['edits'].delete(edit)
    save_corrections(corrections)
    true
  end
end
