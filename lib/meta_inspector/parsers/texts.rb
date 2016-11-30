module MetaInspector
  module Parsers
    class TextsParser < Base
      delegate [:parsed, :meta] => :@main_parser

      # Returns the parsed document title, from the content of the <title> tag
      # within the <head> section.
      def title
        @title ||= parsed.css('head title').inner_text rescue nil
      end

      def best_title
        @best_title = meta['og:title'] if meta['og:title']
        @best_title ||= find_best_title
      end

      # Returns the parsed site name title, from the contents of the several likely tags
      # within the <head> section.
      def best_site_name
        @best_site_name = meta['og:site_name'] if meta['og:site_name']
        @best_site_name ||= find_best_site_name
      end

      # A description getter that first checks for a meta description
      # and if not present will guess by looking at the first paragraph
      # with more than 120 characters
      def description
        return meta['description'] unless meta['description'].nil? || meta['description'].empty?
        secondary_description
      end

      private

      # Look for candidates and pick the longest one
      def find_best_title
        candidates = [
            parsed.css('head title'),
            parsed.css('body title'),
            meta['og:title'],
            parsed.css('h1').first
        ]
        find_best_candidate(candidates)
      end

      def find_best_site_name
        candidates = [
            meta['application-name'],
            meta['og:site_name'],
            parsed.css('h1').first
        ]
        find_best_candidate(candidates, sort_order: :shortest)
      end

      def find_best_candidate(candidates, sort_order: :longest)
        candidates.flatten!
        candidates.compact!
        candidates.map! { |c| (c.respond_to? :inner_text) ? c.inner_text : c }
        candidates.map! { |c| c.strip }
        return nil if candidates.empty?
        candidates.map! { |c| c.gsub(/\s+/, ' ') }
        candidates.uniq!
        candidates.sort_by! { |t| (sort_order == :longest ? -1 : 1) * t.length }
        candidates.first
      end

      # Look for the first <p> block with 120 characters or more
      def secondary_description
        first_long_paragraph = parsed.search('//p[string-length() >= 120]').first
        first_long_paragraph ? first_long_paragraph.text : ''
      end
    end
  end
end
