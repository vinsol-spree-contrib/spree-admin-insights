class Spree::TrendingSearchReport::FrequencyDistributionPieChart
  attr_accessor :chart_data

  def initialize(result)
    total_occurrences = result.observations.sum(&:occurrences).to_f
    self.chart_data = result.observations.collect { |x| { name: x.searched_term, y: x.occurrences.to_i/total_occurrences } }
  end

  def to_h
    {

      name: 'trending-search',
      json: {
        chart: { type: 'pie' },
        title: {
          useHTML: true,
          text: "<span class='chart-title'>Trending Search Keywords(Top 20)</span><span class='fa fa-question-circle' data-toggle='tooltip' title='Track the most trending keywords searched by users'></span>"
        },
        tooltip: {
          pointFormat: 'Search %: <b>{point.percentage:.1f}%</b>'
        },
        plotOptions: {
          pie: {
            allowPointSelect: true,
            cursor: 'pointer',
            dataLabels: {
              enabled: false
            },
            showInLegend: true
          }
        },
        series: [
          {
            name: 'Hits',
            data: chart_data
          }
        ]
      }
    }
  end
end
