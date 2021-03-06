module MuseumProvenance

  # A utility class for extracting dates in strings.
  # Used on top of Chronic, but first tries to pull dates with lesser 
  # precision out of the text.
  class DateExtractor
    
    # Find dates within a string.
    # 
    # @example
    #  DateExtractor.find_dates_in_string("my favorite day was January 15, 1980, when I learned about ice cream.")
    #  # returns [Tue, 15 Jan 1980]
    #  
    #  DateExtractor.find_dates_in_string("the 15th Century was hard, but the 1980s were harder.")
    #  # returns [Sat, 01 Jan 1401, Tue, 01 Jan 1980]
    #  
    #  DateExtractor.find_dates_in_string("I like cheese.")
    #  # returns []
    #
    # @param str [String] The string to search for dates
    # @return [Array<Date>] An array of dates found within the string
    def DateExtractor.find_dates_in_string(str)

          # Substitution for euro-dates: "9 June 1932" or "9 June, 1932" becomes "June 9, 1932"
          euro_dates_regex = /\b(\d{1,2})\s(jan|january|feb|february|febuary|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\.?,?\s(\d{2,4})/i
          str.gsub!(euro_dates_regex, ' \2 \1, \3')


          centuries, str = extract_centuries(str)
          decades, str = extract_decades(str)
          years, str = extract_years(str)
          months, str = extract_months(str)
          days, str = extract_days(str)


          [centuries, decades, years, months, days].flatten.compact
        end
      end

      def DateExtractor.remove_dates_in_string(str)
        # Substitution for euro-dates: "9 June 1932" or "9 June, 1932" becomes "June 9, 1932"
        euro_dates_regex = /\b(\d{1,2})\s(jan|january|feb|february|febuary|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\.?,?\s(\d{2,4})/i
        str.gsub!(euro_dates_regex, ' \2 \1, \3')


        centuries, str = extract_centuries(str)
        decades, str = extract_decades(str)
        years, str = extract_years(str)
        months, str = extract_months(str)
        days, str = extract_days(str)
        return str.gsub(/\s\s*/, " ")
      end
 
      private

      def DateExtractor.extract_centuries(str) 
        century_regex = /\b(?:the\s)?(\d{1,2})(?:st|rd|th|nd)?\s+century(?:\s+(ad|bc|bce|ce))?\b(\?)?/i
        centuries = []
        century = str.match century_regex
        until century.nil?
          centuries.push century
          century = century.post_match.match century_regex
        end
        centuries = centuries.collect do |c|
          is_BCE = c[2] && (c[2].upcase == "BC" || c[2].upcase == "BCE")
          
          val = (c[1].to_s + "01").to_i - 100
          val = ((val + 99) * -1) if is_BCE
         
          uncertain = c[3] && c[3] == "?"

          century = Date.new(val)
          century.precision = DateTimePrecision::CENTURY
          century.certainty = !uncertain
          century
        end
        return centuries, str.gsub(century_regex," ")
      end

      def DateExtractor.extract_decades(str)
        decade_regex =/\b(\d{1,3})0s(?:\s+(ad|bc|bce|ce))?\b(\?)?/i
        decades = []
        decade = str.match decade_regex
        until decade.nil?
          decades.push decade
          decade = decade.post_match.match decade_regex
        end

        decades = decades.collect do |d|
          val = (d[1].to_s + "0").to_i
          is_BCE = d[2] && (d[2].upcase == "BC" || d[2].upcase == "BCE")
          if !is_BCE && val > 100
            uncertain = d[3] && d[3] == "?"
            decade = Date.new(val)
            decade.precision = DateTimePrecision::DECADE
            decade.certainty = !uncertain
            decade
          else
            nil
          end
        end
        return decades, str.gsub(decade_regex," ")
      end

      def DateExtractor.extract_years(str)
          years_regex = /
            (?<!(?:january|febuary|october)\s) # ignore months...
            (?<!(?:march|april)\s)
            (?<!(?:june|july|sept)\s)
            (?<!(?:august)\s)
            (?<!(?:september)\s)
            (?<!(?:december|november|february)\s)
            (?<!(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s)
            (?<!(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\.\s) # ...lots of months, these ones with the dot
            (?<!(?:january|febuary|october),\s) # same thing, but with preceding commas...
            (?<!(?:march|april),\s)
            (?<!(?:june|july|sept),\s)
            (?<!(?:august),\s)
            (?<!(?:september),\s)
            (?<!(?:december|november|february),\s)
            (?<!(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec),\s)
            (?<!(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\.,\s) 
            (?<!\d,\s)  # preceding digit and comma, for jan 1, 2014, to ignore the 1
            (?<!\d\s)  # preceding digit, for jan 1 2014, to ignore the 1
            (?<!\d(?:st|rd|th|nd)\s)  # ordinal, for jan 1st 2014, to ignore the 1
            (?<!\d(?:st|rd|th|nd),\s)  # preceding digit, for jan 1st, 2014, to ignore the 1
            (?<!\/)                    # preceding slash for to ignore traditional dates
            (?<!-)                    # preceding slash for to ignore xml dates
            \b
            (?:
              (?<year_result>\d{4}) # capture years 1000-9999
              (?:\s+(?<era_result>ad|bc|bce|ce))? # optionally capture era
              |
              (?<year_result>\d{1,3}) # capture years 0-999
              (?:\s+(?<era_result>ad|bc|bce|ce)) # capture era
            )
            \b  
            (?!\scentury) # ignore centuries
            (?!\/) # ignore following slash to ignore traidtional dates
            (?!-) # ignore following dash to ignore xml dates
            (?<certainty_result>\?)? # Optionally capture uncertainty
          /ix
          years = []
          year = str.match years_regex
          until year.nil?
            years.push year
            year = year.post_match.match years_regex
          end
          
          years = years.collect do |c|
            is_BCE = c[:era_result] && (c[:era_result].upcase == "BC" || c[:era_result].upcase == "BCE")
            uncertain = c[:certainty_result] && c[:certainty_result] == "?"
            val = c[:year_result].to_i
            val = val * -1 if is_BCE
            d = Date.new(val)
            d.certainty = !uncertain
            d
          end
          return years, str.gsub(years_regex, " ")

      end

      def DateExtractor.extract_months(str)
        month_regex =/\b
                         (?:jan|january|feb|february|febuary|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)
                         \.?,?    # possible punctuation
                         \s       # and a space 
                         \d{1,4}  # the year
                         (?:\s+(ad|bc|bce|ce))?  # the optional era
                         (?!,)       # skip it if it is followed by a comma , which might be a BAD IDEA. 
                         (?!\s\d)    # skip it if it is followed by a digit
                         \b
                         (\?)? # Optionally capture uncertainty
                       /ix
          months = []
          month = str.match month_regex
          until month.nil?
            months.push month
            month = month.post_match.match month_regex
          end

          months = months.collect do |d|
            date_val = d[0].to_s
            certain = date_val.gsub!("?","")
            val = Chronic.parse(date_val).to_date
            m = Date.new(val.year,val.month)
            m.certainty = certain.nil?
            m
          end
          return months, str.gsub(month_regex, " ")

      end

      def DateExtractor.extract_days(str)
        day_regex = /\b
                      (?:jan|january|feb|february|febuary|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)
                      \.?,?\s\d{1,2}
                      (?:st|rd|th|nd)?\s?
                      ,?
                      \s\d{1,4}
                      (?:\s+(ad|bc|bce|ce))?
                      \b
                      (\?)? # Optionally capture uncertainty
                    /ix
          days = []
          day = str.match day_regex
          until day.nil?
            days.push day
            day = day.post_match.match day_regex
          end

          traditional_day_regex = /\b
            \d{1,2}\/\d{1,2}\/\d{2,4}
            (?:\s+(ad|bc|bce|ce))?
            \b
            (\?)? # Optionally capture uncertainty
          /ix
          day = str.match traditional_day_regex
          until day.nil?
            days.push day
            day = day.post_match.match traditional_day_regex
          end

          xml_day_regex = /\b
            \d{2,4}-\d{1,2}-\d{1,2}
            \b
            (\?)? # Optionally capture uncertainty
          /ix
          day = str.match xml_day_regex
          until day.nil?
            days.push day
            day  = day.post_match.match xml_day_regex
          end

          days = days.collect do |d|
            date_val = d[0].to_s
            certain = date_val.gsub!("?","")
            is_BCE = d[1] && (d[1].upcase == "BC" || d[1].upcase == "BCE")
            day = Chronic.parse(date_val)
            unless day.nil?
              day = day.to_date 
              day = Date.new(day.year*-1,day.month,day.day) if is_BCE
              day.certainty = certain.nil?
            end
            day
          end
          str = str.gsub(day_regex, " ").gsub(traditional_day_regex, " ").gsub(xml_day_regex, " ")
          return days, str
      end
    end