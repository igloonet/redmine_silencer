module RedmineSilencer
  class IssueHooks < Redmine::Hook::Listener
    def controller_issues_edit_before_save(context)
      update_journal_notify(context[:params], context[:issue], context[:journal])
    end

    def controller_issues_bulk_edit_before_save(context)
      update_journal_notify(context[:params], context[:issue], context[:issue].current_journal)
    end

    private

    def update_journal_notify(params, issue, journal)
      return unless journal && params

      journal.notify = false if suppress_requested?(params, journal) || status_only_change?(issue, journal)
    end

    def suppress_requested?(params, journal)
      params[:suppress_mail] == '1' &&
        User.current.allowed_to?(:suppress_mail_notifications, journal.project)
    end

    # An update in which the user changed the status and nothing else (no notes,
    # no other attribute, custom field or attachment) sends no notification.
    # Decided from what the user submitted, before the issue is saved: changes
    # made by callbacks during save (done ratio from status, custom workflows)
    # do not count.
    def status_only_change?(issue, journal)
      return false unless issue&.status_id_changed?
      return false if journal.notes.present?
      # Same rules as Journal#journalize_changes: blank -> blank is no change
      # (the edit form sends "" for an empty description)
      changed = issue.changes.slice(*issue.journalized_attribute_names)
                     .select { |_, (before, after)| value_changed?(before, after) }
      return false if changed.keys != ['status_id']
      return false if issue.custom_field_values.any? { |v| value_changed?(v.value_was, v.value) }

      issue.saved_attachments.empty? && issue.deleted_attachment_ids.empty?
    end

    def value_changed?(before, after)
      if before.is_a?(Array) || after.is_a?(Array)
        before = Array(before).reject(&:blank?).sort
        after = Array(after).reject(&:blank?).sort
      end
      before != after && !(before.blank? && after.blank?)
    end
  end
end
