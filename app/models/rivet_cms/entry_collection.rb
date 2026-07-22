module RivetCms
  # Enumerable page of entries with the pagination numbers host views need.
  class EntryCollection
    include Enumerable

    attr_reader :page, :per_page, :total, :total_pages

    def initialize(entries, page: 1, per_page: entries.size, total: entries.size, total_pages: 1)
      @entries = entries
      @page = page
      @per_page = per_page
      @total = total
      @total_pages = total_pages
    end

    def each(&block)
      @entries.each(&block)
    end

    def to_a
      @entries.dup
    end

    def size
      @entries.size
    end
    alias length size

    def [](index)
      @entries[index]
    end

    def empty?
      @entries.empty?
    end

    def inspect
      "#<RivetCms::EntryCollection size=#{size} page=#{page}/#{total_pages} total=#{total}>"
    end
  end
end
