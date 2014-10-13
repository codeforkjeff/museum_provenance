require "csv"
module MuseumProvenance
  # Timeline is the main representation of the provenance of an artwork.
  # It's a container for a ordered array of {Period}s, representing the individual
  # ownership moments of the paintings.  They can be accessed as array objects, or
  # via the linked-list style implementation.
  # 
  # It extends Enumerable, and will respond to both #first and #last.
  class Timeline
    include Enumerable

    # @!attribute [r] earliest
    #   @return [String] The earliest period within the timeline. 
    # @!attribute [r] latest
    #   @return [String] The latest period within the timeline.
    attr_reader :earliest, :latest

    # @return [String] The provenance of the timeline.
    # @see #provenance
    def to_s
      provenance
    end

    # Array access to the {Period}s contained within the Timeline.
    # @param n [Fixnum] The provenance record desired
    # @return [Period]
    def [](n)
      current = earliest
      n.times do 
        next if current.nil?
        current = current.next_period
      end
      current
    end

    # @return [Period] The most recent period.
    # @see latest
    def last
      return latest
    end

    # Standard Enumerable method for yielding a block to each {Period} within the {Timeline}.
    # @return [Void]
    def each
      current = earliest
      while !current.nil?
        yield current
        current = current.next_period
      end
    end
    
    # Generates a CSV for the timeline.
    # @return [CSV] A CSV_String representation of the timeline.
    def to_csv
       CSV.generate do |csv|
          csv << PeriodOutput.members
          self.each do |p|
            csv << p.generate_output.to_a
          end
       end
    end

    # @return [JSON] a JSON string of the timeline
    # @todo Not currently implemented.
    def to_json
    end

    # Generates the complete provenance of all Periods within the Timeline.
    # It also re-numbers and re-attaches the footnotes, seperated by {Provenance::FOOTNOTE_DIVIDER}.
    def provenance
      footnotes = []
      records = self.collect do |r| 
        record = r.provenance
        if r.has_note?
          [r.note].flatten.each do |n|
            footnotes.push n
            record += " [#{footnotes.count}]"
          end
        end
        record += r.direct_transfer == true ? ";" : "." 
      end.join(" ")
      footnotes = footnotes.collect.with_index{|n,i| "#{i+1}. #{n}"}
      footnote_split = nil
      footnote_split = Provenance::FOOTNOTE_DIVIDER unless footnotes.blank?
      [records, footnote_split, footnotes].flatten.join(" ").strip
    end
    

    # Insert a new period at the end of the timeline
    # and mark the previous period as a direct transfer.
    # Will function the same as {#insert} if there is not a preceding period.
    # @param period [Period]
    # @return [Void]
    def insert_direct(period)
      insert_latest(period)
      period.previous_period.direct_transfer = true unless period.previous_period.nil?
    end

    # Insert a new period directly before another period.
    # This allows insertion in arbitrary order.
    # @param period [Period] the new period.
    # @param following_period [Period] the period you wish to insert in front of.
    # @return [Void]
    def insert_before(following_period,period)
      period.previous_period = following_period.previous_period
      period.next_period  = following_period
      if following_period.previous_period.nil?
        @earliest = period
      else
        following_period.previous_period.next_period  = period
      end
      following_period.previous_period = period
    end

    # Insert a new period directly after another period.
    # This allows insertion in arbitrary order.
    # @param period [Period] the new period.
    # @param preceding_period [Period] the period you wish to insert behind.
    # @return [Void]
    def insert_after(period,preceding_period)
      preceding_period.previous_period = period
      preceding_period.next_period = period.next_period
      if period.next_period.nil?
        @latest = preceding_period
      else
        period.next_period.previous_period = preceding_period
      end
      period.next_period  = preceding_period
    end

    # Same as {#insert_after}, but wil also mark ther period as a direct transfer.
    # @param period [Period] the new period.
    # @param preceding_period [Period] the period you wish to insert behind.
    # @return [Void]
    def insert_directly_after(period,preceding_period)
      insert_after(period,preceding_period)
      period.direct_transfer = true
    end

    # Insert a new period at the end of the timeline.
    # @param period [Period]
    # @return [Void]
    def insert_latest(period)
      if latest.nil?
        insert_earliest(period)
      else
        insert_after(latest, period)
      end
    end
    alias :insert :insert_latest

    # Insert a new period at the beginning of the timeline.
    # @param period [Period]
    # @return [Void]
    def insert_earliest(period)
      if earliest.nil?
        @earliest = period
        @latest = period
        period.previous_period = nil
        period.next_period = nil
      else
        insert_before(earliest, period)
      end
    end
  end
end