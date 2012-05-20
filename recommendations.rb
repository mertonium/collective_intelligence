require 'www/delicious'

class Recommendations
  # A dictionary of movie critics and their ratings of a small
  # set of movies
  def self.critics
    {
      'Lisa Rose' => {
        'Lady in the Water' => 2.5,
        'Snakes on a Plane'=> 3.5,
        'Just My Luck' => 3.0,
        'Superman Returns' => 3.5,
        'You, Me and Dupree' => 2.5,
        'The Night Listener' => 3.0
      },
      'Gene Seymour' => {
        'Lady in the Water' => 3.0,
        'Snakes on a Plane' => 3.5,
        'Just My Luck' => 1.5,
        'Superman Returns' => 5.0,
        'The Night Listener' => 3.0,
        'You, Me and Dupree' => 3.5
      },
      'Michael Phillips' => {
        'Lady in the Water' => 2.5,
        'Snakes on a Plane' => 3.0,
        'Superman Returns' => 3.5,
        'The Night Listener' => 4.0
      },
      'Claudia Puig' => {
        'Snakes on a Plane' => 3.5,
        'Just My Luck' => 3.0,
        'The Night Listener' => 4.5,
        'Superman Returns' => 4.0,
        'You, Me and Dupree' => 2.5
      },
      'Mick LaSalle' => {
        'Lady in the Water' => 3.0,
        'Snakes on a Plane' => 4.0,
        'Just My Luck' => 2.0,
        'Superman Returns' => 3.0,
        'The Night Listener' => 3.0,
        'You, Me and Dupree' => 2.0
      },
      'Jack Matthews' => {
        'Lady in the Water' => 3.0,
        'Snakes on a Plane' => 4.0,
        'The Night Listener' => 3.0,
        'Superman Returns' => 5.0,
        'You, Me and Dupree' => 3.5
      },
      'Toby' => {
        'Snakes on a Plane' => 4.5,
        'You, Me and Dupree' => 1.0,
        'Superman Returns' => 4.0
      }
    }
  end


  def self.sim_distance(prefs,person1,person2)
    # Get the list of shared_items
    si =  {}

    prefs[person1].keys.each do |item|
      # puts item
      if prefs[person2].keys.include? item
        si[item] = 1
      end
    end

    # if they have no ratings in common, return 0
    return 0 if si.length == 0

    sum_of_squares = 0
    si.keys.each do |item|
      sum_of_squares += (prefs[person1][item] - prefs[person2][item])**2
    end

    return 1/(1+Math.sqrt(sum_of_squares))
  end

  # Returns the Pearson correlation coefficient for p1 and p2
  def self.sim_pearson(prefs,p1,p2)
    # Get the list of mutually rated items
    si={}

    prefs[p1].keys.each do |item|
      if prefs[p2].keys.include? item
        si[item] = 1
      end
    end

    # Find the number of elements
    n = si.length

    # if they have no ratings in common, return 0
    return 0 if n == 0

    sum1 = 0
    sum2 = 0
    sum1Sq = 0
    sum2Sq = 0
    pSum = 0

    si.keys.each do |it|
      # Add up all the preferences
      sum1 += prefs[p1][it]
      sum2 += prefs[p2][it]
      # Sum up the squares
      sum1Sq += prefs[p1][it]**2
      sum2Sq += prefs[p2][it]**2;
      # Sum up the products
      pSum += prefs[p1][it]*prefs[p2][it]
    end

    # Calculate Pearson score
    num = pSum - (sum1 * sum2 / n)
    den = Math.sqrt((sum1Sq - sum1**2 / n) * (sum2Sq - sum2**2 / n))

    return 0 if den == 0

    r = num / den

    return r
  end

  # Returns the best matches for person from the prefs dictionary.
  # Number of results and similarity function are optional params.
  def self.topMatches(prefs,person, n=3, similarity = :sim_pearson)
    scores = []
    prefs.keys.each { |other| scores << Hash[self.send(similarity, prefs, person, other), other] unless other == person }

    # scores=[(similarity(prefs,person,other),other)
    #                 for other in prefs if other!=person]

    # Sort the list so the highest scores appear at the top
    scores.sort_by! { |i| i.keys.first }
    scores.reverse!
    return scores.slice(0,n)
  end
  
  # Gets recommendations for a person by using a weighted average
  # of every other user's rankings
  def self.getRecommendations(prefs, person, similarity = :sim_pearson)
    totals = {}
    simSums = {}
    
    prefs.keys.each do |other|
      # don't compare me to myself
      if other != person
        sim = self.send(similarity, prefs, person, other)
        totals.default = 0
        simSums.default = 0
        # ignore scores of zero or lower
        if sim > 0
          prefs[other].keys.each do |item|
            # only score movies I haven't seen yet
            if !prefs[person].keys.include? item || prefs[person][item] == 0
              # Similarity * Score
              totals[item] += prefs[other][item] * sim
              simSums[item] += sim
            end
          end
        end
      end
    end
    puts totals
    
    rankings = []
    totals.each do |item, total|
      rankings << Hash[total/simSums[item], item]
    end
    
    puts rankings
    rankings.sort_by! { |i| i.keys.first }
    rankings.reverse!
    
    return rankings
  end
  
  def self.transformPrefs(prefs)
    kys = []
    results = {}
    prefs.each { |i, val| kys << val.keys }
    kys.flatten!.uniq!

    kys.each do |k|
      results[k] = {}
    end
    
    prefs.keys.each do |person|
      prefs[person].each do |item, val|
        results[item].merge!(Hash[person,val])
      end
    end
    
    return results
  end
  
  def self.calculateSimilarItems(prefs,n=10)
    # Create a dictionary of items showing which other items they
    # are most similar to.
    result={}

    # Invert the preference matrix to be item-centric
    itemPrefs = self.transformPrefs(prefs)
    c = 0

    itemPrefs.keys.each do |item|
      # Status updates for large datasets
      c += 1
      puts "#{c} / #{itemPrefs.length}" if c % 100 == 0

      # Find the most similar items to this one
      scores = topMatches(itemPrefs,item,n=n,similarity=:sim_distance)
      result[item]=scores
    end
    return result
  end
end