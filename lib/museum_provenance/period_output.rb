module MuseumProvenance
    # A Struct for holding all the information about a period, used for export and import.
    PeriodOutput = Struct.new :period_certainty,
                              :acquisition_method,
                              :party,
                              :party_certainty,
                              :birth,
                              :birth_certainty,
                              :death,
                              :death_certainty,
                              :location,
                              :location_certainty,
                              :botb,
                              :botb_certainty,
                              :botb_precision,
                              :eotb,
                              :eotb_certainty,
                              :eotb_precision,
                              :bote,
                              :bote_certainty,
                              :bote_precision,
                              :eote,
                              :eote_certainty,
                              :eote_precision,
                              :original_text,
                              :provenance,
                              :parsable,
                              :direct_transfer,
                              :stock_number,
                              :footnote
end