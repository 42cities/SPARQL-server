module SPARQL
  module Server
    class Request
      class << self

        ##
        # [-]
        ##
        def to_xml(query, schema, options = {})
          options[:namespaces] ||= {}
          RDF::Writer.for(:xml).buffer do |writer|
            options[:namespaces].each do |ns, uri|
              writer.namespace!(uri, ns)
            end
            if options[:base]
              writer.base!(options[:base])
            end
            find(query, schema).map do |item|
              item.to_triples.each do |triple|
                writer << triple
              end
            end
          end
        end

        ##
        # [-]
        ##
        def find(string, schema)
          items = {}
          reader = RDF::Reader.for(:sparql).new(string)

          unless reader.type == :describe
            raise BadRequest, 'Only `DESCRIBE` queries are allowed'
          end

          reader.triples.flatten.uniq.each do |item|
            items[item] = Item.new(item, schema)
          end

          reader.each_statement do |statement|
            triple = statement.to_triple.map { |item| items[item] }
            triple.each { |item| item << triple }
          end

          reader.targets.each do |target|
            items[target] ||= Item.new(target, schema)
          end

          reader.targets.map do |target|
            items[target].instances.to_a
          end.flatten
        end
      end
      
      class BadRequest < RuntimeError; end
      
      class Item

        attr_reader :object
        attr_reader :masters

        ##
        # [-]
        ##
        def initialize(object, schema)
          @schema = schema
          @object = object
          @conditions = []
        end

        ##
        # [-]
        ##
        def ==(other)
          other.kind_of?(Item) ? @object == other.object : @object == other
        end

        ##
        # [-]
        ##
        def <<(triple)
          @conditions << triple
        end

        ##
        # [-]
        ##
        def instances
          rdf_class ? rdf_class.find(:all, :conditions => find_options) : []
        end

        ##
        # [-]
        ##
        def to_sql(name)
          predefined? ? value_to_sql(name) : model_to_sql(name)
        end

        ##
        # [-]
        ##
        def solvable?
          predefined? or rdf_type
        end

        ##
        # [-]
        ##
        def rdf_class
          @schema.select { |cls| cls.type == rdf_type }.first
        end

        ##
        # [-]
        ##
        def belongs_to?(other)
          if rdf_class.nil? or other.rdf_class.nil?
            return false
          end 
          attribute = rdf_class.has?(nil, other.rdf_class)
          if attribute.nil? or not attribute.belongs_to?
            return false
          end
          attribute.type
        end
        
        def inspect
          @object
        end

        private

        ##
        # [-]
        ##
        def find_options #nodoc
          text, ary = [], []
          (parents + attributes).each do |c|
            text.push(c.first)
            ary.push(*c.last)
          end
          [text.join(' AND ')] + ary
        end

        ##
        # [-]
        ##
        def parents #nodoc
          as_objects.select { |c| belongs_to?(c[0]) }.map { |c| c[0].to_sql(belongs_to?(c[0])) }
        end

        ##
        # [-]
        ##
        def attributes #nodoc
          as_subject.select { |c| c[2].solvable? and not c[2].belongs_to?(self) }.map { |c| c[2].to_sql(c[1].object) }
        end

        ##
        # [-]
        ##
        def rdf_type #nodoc
          as_class.map { |c| c[2].object }.first
        end

        ##
        # [-]
        ##
        def as_subject #nodoc
          @conditions.select { |c| c[0] == self }.reject { |c| c[1] == RDF.type }
        end

        ##
        # [-]
        ##
        def as_objects #nodoc
          @conditions.select { |c| c[2] == self }
        end

        ##
        # [-]
        ##
        def as_class #nodoc
          @conditions.select { |c| c[0] == self && c[1] == RDF.type }
        end

        ##
        # [-]
        ##
        def variable? #nodoc
          @object.class == RDF::Query::Variable
        end

        ##
        # [-]
        ##
        def model_to_sql(name) #nodoc
          ["%s IN (?)" % name, instances]
        end

        ##
        # [-]
        ##
        def value_to_sql(name) #nodoc
          variable? ? variable_to_sql(name) : ["%s = %s" % [name, @object.to_s], []]
        end

        ##
        # [-]
        ##
        def variable_to_sql(name) #nodoc
          ary = @object.values.map do |modifier, value|
            value = '"%s"' % value if value.class == String
            "%s %s %s" % [name, modifier, value]
          end
          str = ary.join(@object.strict? ? " AND " : " OR ")
          ["(%s)" % str, []]
        end

        ##
        # [-]
        ##
        def predefined? #nodoc
          case @object
            when RDF::URI               then true
            when RDF::Literal           then true
            when RDF::Query::Variable   then @object.bound?
            else false
          end
        end

      end # Item
    end # Request
  end # Server
end # SPARQL

