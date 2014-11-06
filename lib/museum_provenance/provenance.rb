module MuseumProvenance
  
  # This is a utility class for extracting a {Timeline} from a String.
  class Provenance

    # A list of abbreviations.  A "." following any of these will not signify a new period.
    ABBREVIATIONS  = ["Mme.", "Mr.", "Mrs.", "Dr.", "no.", "No.", "Esq.", "Co.", "St.", "illus.", "inc.", "Inc.", "Jr.", "Sr.", "Ltd.", "Dept.", "M.","P.", "Miss.", "Ph.D", "DC.", "D.C."]
    # A list of name suffixes.  A "," preceding any of these will not signify the end of a name.
    NAME_EXTENDERS = ["Esq", "Jr", "Sr", "Count", "Earl", "Inc.", "Ltd.", "LLC", "llc", "Lord", "MP", "M.P.", 
      "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "son of", "daughter of", "wife of", "husband of", "the artist", "his wife", "her husband", "his nephew", "his son", "his daughter", "her daughter", "her son", "their daughter", "their son"]
    # A character used to stand in for a period during parsing.  Only used internally.
    FAKE_PERIOD = "\u2024"
    # The string used to seperate the footnotes of a provenance record from the actual records.
    FOOTNOTE_DIVIDER = "NOTES:"


    class << self

      # Extract structured provenance data from a provenance text.
      # @param provenance_string [String] The textual provenance record
      # @return [Timeline] The structured representation of the provenance
      def extract(provenance_string)
        provenance_string.gsub!("\n"," ")
        text, notes = extract_text_and_notes(provenance_string)
        timeline = generate_timeline(text)
        unless notes.nil?
          notes = split_notes(notes)
        end
        timeline.each do |line| 
          line.note = line.note.collect{|num| notes[num]} if line.note
        end
        timeline
      end

      # Extract a provenance record from JSON. 
      # @param json [String] a JSON string representing a provenance record.
      # @return [Timeline] The structured representation of the provenance
      def from_json(json)
        timeline = Timeline.new
        last_was_direct = false
        if json.is_a? String
          data = JSON.parse(json, {symbolize_names: true})
        elsif json.is_a? Hash
            data = json
        else
          raise "I don't know what!"
        end
        data[:period].each do |period|
          p = Period.new("",period)
          if last_was_direct 
            timeline.insert_direct(p)
          else
            timeline.insert(p)
          end
          last_was_direct = period[:direct_transfer].to_bool
        end
        return timeline    
      end

      private

      def extract_text_and_notes(input)
        text, notes = input.split(FOOTNOTE_DIVIDER)
        if notes.nil?  
         text, notes = input.split(" 1. ")
         notes = "1. " + notes if notes
        end
        if notes.nil? 
          text = input
        end
        text = text.strip
        notes = notes.strip if notes
        [text, notes]
      end

      def split_notes(notes)
      if notes.strip[0] == "["
        notes = notes.strip.split("[").compact.map do |note|
          note.scan(/^(\d+)\]?\s*(.*)/).flatten 
        end
      elsif notes[0..1] == "1."
        notes = notes.scan(/
          (\d+)\.\s  # digits, period, space
          (.*?)      # everything until...
          (?=\d+\.\s # digit period space ...
            (?:\D|\d+(?!\.)) # where the next character is not a digit followed by a period 
                             #  avoiding the 1. Sometime in 1950. 2. Something. probem.
          |$)  # OR eot 
        /ix)
      end
      hash = {}
      notes.each {|note| hash[note[0]] = note[1].strip unless note[0].nil?}
      hash
    end

      #--------------------------------------------------------
      # This will replace all periods in the record that are not record seperators with \u2024, which is "․"
      #--------------------------------------------------------
      def substitute_periods(text)
        modified = text.gsub(/b\. (\d{4})/, 'BORN \1') || text  # born
        modified.gsub!(/d\.\s(\d{4})/, 'DIED \1')   # died
        modified.gsub!(/(\s[A-Z])\./, "\\1#{FAKE_PERIOD}") # initials
        modified.gsub!(/^([A-Z])\./, "\\1#{FAKE_PERIOD}") # intial initials
        ABBREVIATIONS.each {|title| modified.gsub!(title, title.gsub(".",FAKE_PERIOD))}
        modified
      end

      #--------------------------------------------------------
      # Scan a given block of text for birth and death dates.
      #--------------------------------------------------------
      def find_birth_and_death(text) 
        return text, nil if text.blank?

        b,d = nil,nil

        birth_death_regex = /
          \s*?         # leading whitespace
          [\(|\[]      # Date bracketing — open paren or bracket
          (?!BORN)
          (?!DIED)
          \s*?          # any char
          (\d{3,4})?    # one to four numbers
          (\?)?         # find certainty
          \s?\D?\s?     # single char splitter, maybe surrounded by spaces
          (\d{3,4})?    # one to four numbers
          (\?)?         # find certainty
          [\)|\]]      # close paren or brackets
          \s*?         # trailing whitespace
        /ix

        death_regex = /
          \s*?         # leading whitespace
          [\(|\[]      # Date bracketing — open paren or bracket
          \s*?         # any number of whitespaces
          DIED\s
          (\d{3,4})
          (\?)?         # find certainty
          \s*?         # any number of whitespaces
          [\)|\]]      # Date bracketing — close paren or bracket
          \s*?         # trailing whitespace
        /ix

        birth_regex = /
          \s*?         # leading whitespace
          [\(|\[]      # Date bracketing — open paren or bracket
          \s*?         # any number of whitespaces
          BORN\s
          (\d{3,4})
          (\?)?         # find certainty
          \s*?         # any number of whitespaces
          [\)|\]]      # Date bracketing — close paren or bracket
          \s*?         # trailing whitespace
        /ix

        if (range = text.scan(birth_death_regex).flatten) != []
          b, bcert, d, dcert = range
          unless b.nil?
            b = DateExtractor.find_dates_in_string(b).first 
            b.certainty = bcert.nil?
          end
          unless d.nil?
            d = DateExtractor.find_dates_in_string(d).first 
            d.certainty = dcert.nil?
          end
        else
          if (range = text.scan(death_regex)) != []
            death, dcert = range.flatten
            d = DateExtractor.find_dates_in_string(death).first
            d.certainty = dcert.nil?
          end
          if (range = text.scan(birth_regex)) != []
            birth, bcert = range.flatten
            b = DateExtractor.find_dates_in_string(birth).first
            b.certainty = bcert.nil?
          end
        end
        text = text.gsub(birth_death_regex,"")
        text = text.gsub(birth_regex,"")
        text = text.gsub(death_regex, "")
        return [b,d,text]
      end

      def extract_acquisition_method(text) 
        return text, nil if text.blank?
        acquisition_method = AcquisitionMethod.find(text)
        if acquisition_method
          f = acquisition_method.forms
          f.sort_by{|t| t.length}.reverse.each do |form|
            new_text = text.gsub(/(:?,\s)?#{form}/i,"")
            if new_text != text
              text = new_text
              break
            end
          end
        end
        return text.strip, acquisition_method
      end

      def extract_footnotes(text)
         footnotes = text.scan(/\[(\d+)\]/)
         footnotes += text.scan(/\[.*?note (\d+)\]/)
         footnotes.flatten!
         text.gsub!(/\[(\d+)\]/,"")
         text.gsub!(/\[.*?note (\d+)\]/,"")
         return footnotes, text.strip
      end

      def extract_certainty(text) 
        record_is_certain = true
        return record_is_certain if text.blank?
        Certainty::CertantyWords.each do |w|
          if text.split(" ").first.include?(w)
            record_is_certain = false 
            text_array = text.split(" ")
            val = text_array.shift()
            val = val.gsub!(w,"")
            text_array.unshift val unless val.empty?
            text = text_array.join(" ")
            break
          end
        end
        return  record_is_certain, text.strip
      end

      def extract_name_and_location(text)
        return text, nil if text.blank?
        name = text.split(",").first
        counter = 1
        while (text.split(", ")[counter].start_with?(*NAME_EXTENDERS) rescue false) do
          name += ", " + text.split(",")[counter].strip
          counter+=1
        end

        begin
          loc = text.split(",")[(counter..-1)].join(",").strip 
          loc = nil if loc == name
        rescue
          loc = nil
        end
        loc = nil if loc == ""
        return name, loc
      end



      def extract_stock_numbers(text)
        return text, nil if text.blank?

        stock_regex = /
          (?:stock\s)?
          no\.\s
          .*\b
        /ix
        lot_regex = /
          \blot\s.*\b
        /ix
        stock = text.scan(stock_regex).first
        stock = text.scan(lot_regex).first if stock.nil?
        text = text.gsub(stock,"").strip if stock
        return stock, text
      end

       def generate_timeline(text)

        # Replace non-terminating periods with FAKE_PERIOD
        t = Timeline.new
        text = substitute_periods(text)
        lines =  text.split(".")
        lines = lines.map{|line| line.split(";").join("\ntransferred: ").split("\n")}.flatten
        lines.each do |line|
          # Put back the periods
          text = line.strip.gsub(FAKE_PERIOD,".")

          # make note of direct transfers
          direct_transfer = !text.scan("transferred: ").empty?
          text = text.gsub("transferred: ","").strip
          
          #extract footnotes
          notes, text = extract_footnotes(text)

          original_text = text

          # pull off record certainty

          record_is_certain , text = extract_certainty(text)


          # pull off acquisition prefixes
          text, acquisition_method = extract_acquisition_method(text)

          # extract birth and death from text
          birth, death, text = find_birth_and_death(text)

          stock_number, text = extract_stock_numbers(text)
            
          # create the period
          generated_period = Period.new()
          generated_period.certain = record_is_certain
          generated_period.original_text = original_text
          generated_period.acquisition_method = acquisition_method
          generated_period.note = notes
          generated_period.stock_number = stock_number
          begin
            text = generated_period.parse_time_string(text) unless text.blank?
          rescue DateError
          end
          ## Link it into the timeline
          
          # split off names and locs
          generated_period.party, generated_period.location = extract_name_and_location(text)

          # add in births and deaths
          generated_period.party.birth = birth
          generated_period.party.death = death

          # handle direct transfers
          if direct_transfer
            begin
              t.insert_direct generated_period
            rescue DateError
            end
          else
            t.insert generated_period
          end
        end
        t
       end

    end
  end
end