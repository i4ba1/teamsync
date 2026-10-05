# Base class for repositories.
#
# A repository is the single boundary between the domain and ActiveRecord for
# a given aggregate: it owns queries, lookups and persistence. Services depend
# on repositories, never the other way around.
class ApplicationRepository
end
