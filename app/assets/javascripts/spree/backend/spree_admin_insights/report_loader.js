//= require spree/backend/spree_admin_insights/paginator
//= require spree/backend/spree_admin_insights/searcher
//= require spree/backend/spree_admin_insights/table_sorter

function ReportLoader(inputs) {
  this.$selectList = inputs.reportsSelectBox;
  this.$insightsTableList = inputs.insightsDiv;
  this.tableHelpers = inputs.tableHelpers;
  this.pageSelector = inputs.tableHelpers.find('#page-selector');
  this.perPageSelector = this.tableHelpers.find('#per_page');
  this.pageHelpers = this.tableHelpers.find('#page-helpers');
  this.resetButton = inputs.resetButton;
  this.refreshButton = inputs.refreshButton;
  this.filterDiv = inputs.filterDiv;
  this.paginatorDiv = inputs.paginatorDiv;
  this.removePaginationButton = inputs.removePaginationButton;
  this.applyPaginationButton = inputs.applyPaginationButton;
  this.chartContainer = inputs.chartContainer;
  this.downloadLinks = inputs.downloadLinks;
  this.requestUrl = '';
  this.isStatePushable = true;
  this.tableSorterObject = null;
  this.searcherObject = null;
  this.paginatorObject = null;
}

ReportLoader.prototype.init = function() {
  var tableSorterInputs = {
    $insightsTable: this.$insightsTableList,
    reportLoader: this,
    paginatorDiv: this.paginatorDiv
  };
  this.tableSorterObject = new TableSorter(tableSorterInputs);
  this.tableSorterObject.bindEvents();

  var searcherInputs = {
    filterDiv:   this.filterDiv,
    insightsDiv: this.$insightsTableList,
    tableSorterObject: this.tableSorterObject
  };
  this.searcherObject = new Searcher(searcherInputs, this);
  this.searcherObject.bindEvents();

  var paginatorInputs = {
    paginatorDiv: this.paginatorDiv,
    insightsDiv: this.$insightsTableList,
    tableSorterObject: this.tableSorterObject,
    removePaginationButton: this.removePaginationButton,
    applyPaginationButton: this.applyPaginationButton
  };
  this.paginatorObject = new Paginator(paginatorInputs, this);
  this.paginatorObject.bindEvents();
  this.setDefaultReport();
};

ReportLoader.prototype.setDefaultReport = function() {
  if(location.pathname == '/admin/insights') {
    this.$selectList.val($(this.$selectList.find('option')[1]).val()).change();
  }
  window.history.pushState({}, '', this.$selectList.find(':selected').data('url'));
};

ReportLoader.prototype.bindEvents = function() {
  var _this = this;
  _this.$selectList.on('change', function() {
    $(this).find('option').first().attr('disabled', true);
    _this.paginatorObject.togglePaginatorButtons(_this.paginatorObject.removePaginationButton, _this.paginatorObject.applyPaginationButton);
    _this.searcherObject.clearSearchFields();
    _this.loadChart($(this).find(':selected'));
  });

  this.resetButton.on('click', function() {
    _this.resetFilters(event);
  });

  this.refreshButton.on('click', function() {
    _this.refreshPage(event);
  });

  _this.bindPopStateEventCallback();
};

ReportLoader.prototype.resetFilters = function(event) {
  event.preventDefault();
  var $element = $(event.target),
      paginated = !this.removePaginationButton.closest('span').hasClass('hide');
  $element.attr('href', this.perPageSelector.data('url') + '&paginate=' + paginated);
  $element.data('url', this.perPageSelector.data('url') + '&paginate=' + paginated);
  this.loadChart($element);
  this.searcherObject.clearSearchFields();
};
 
ReportLoader.prototype.refreshPage = function(event) {
  event.preventDefault();
  var $element = $(event.target);
  $element.attr('href', location.href);
  $element.data('url', location.href);
  this.loadChart($element);
};

ReportLoader.prototype.bindPopStateEventCallback = function() {
  var _this = this;
  window.onpopstate = function(event) {
    event.state ? (report_name = event.state['report_name'] || '') : (report_name = '');
    _this.$selectList.val(report_name);
    _this.$selectList.select2('val', report_name);
    var $selectedOption = _this.$selectList.find(':selected');
    _this.fetchChartDataWithoutState(location.href, $selectedOption);
  };
};

ReportLoader.prototype.loadChart = function($selectedOption) {
  var requestPath = $selectedOption.data('url');
  this.searcherObject.clearSearchFields();
  this.fetchChartData(requestPath, $selectedOption);
};

ReportLoader.prototype.fetchChartData = function(url, $selectedOption) {
  var _this = this;
  _this.requestUrl = url;
  $.ajax({
    type: 'GET',
    url: url,
    dataType: 'json',
    success: function(data) {
      (_this.isStatePushable ? _this.populateInsightsData(data) : _this.populateInsightsDataWithoutState(data))
      if(data.headers != undefined) {
        _this.tableHelpers.removeClass('hide');
        if(data.pagination_required == false) {
          _this.pageSelector.addClass('hide');
          $.each(_this.pageHelpers.find('.col-md-2'), function(index, object) {
            $(object).removeClass('col-md-2').addClass('col-md-3');
          });
        } else {
          _this.pageSelector.removeClass('hide');
          $.each(_this.pageHelpers.find('.col-md-3'), function(index, object) {
            $(object).removeClass('col-md-3').addClass('col-md-2');
          });
        }
        _this.perPageSelector.data('url', data['request_path'] + '?report_category=' + data['report_category']);
        _this.setDownloadLinksPath();
        _this.searcherObject.refreshSearcher($selectedOption, data);
        _this.paginatorObject.refreshPaginator(data);
        if(data.searched_fields != undefined)
          _this.searcherObject.fillFormFields(data.searched_fields);
      }
    }
  });
};

ReportLoader.prototype.buildChart = function(data) {
  var chart_container = $('#chart-container');
  if ((data['chart_json'] != undefined) && (data['chart_json']['chart'])) {
    chart_container.empty().removeClass('hidden');
    $.each(data['chart_json']['charts'], function(index, chart) {
      var chart_div = $('<div>', { id: chart['id'] });
      chart_container.append(chart_div);
      chart_div.highcharts(chart['json']);
    });
  } else {
    chart_container.addClass('hidden');
  }
};

ReportLoader.prototype.fetchChartDataWithoutState = function(url, $selectedOption) {
  this.isStatePushable = false;
  this.fetchChartData(url, $selectedOption);
};

ReportLoader.prototype.populateInsightsData = function(data) {
  if(data.headers != undefined) {
    var $templateData = $(tmpl('tmpl', data));
    this.$insightsTableList.empty().append($templateData);
    this.buildChart(data);
  } else {
    this.$insightsTableList.empty();
    this.paginatorDiv.empty();
    this.filterDiv.addClass('hide');
    this.chartContainer.addClass('hidden');
  }
  if(this.isStatePushable) {
    this.pushUrlToHistory();
  } else {
    this.isStatePushable = true;
  }
};

ReportLoader.prototype.setDownloadLinksPath = function($selectedOption) {
  var _this = this;
  $.each(this.downloadLinks, function() {
    $(this).attr('href', $(this).data('url') + '?id=' + _this.$selectList.val() + '&paginate=false');
  });
};

ReportLoader.prototype.populateInsightsDataWithoutState = function(data) {
  this.isStatePushable = false;
  this.populateInsightsData(data);
};

ReportLoader.prototype.pushUrlToHistory = function() {
  var report_name = this.$selectList.find(':selected').val();
  window.history.pushState({ report_name: report_name }, '', this.requestUrl);
  this.requestUrl = '';
};

ReportLoader.prototype.populateInitialData = function() {
  var $selectedOption = this.$selectList.find(':selected');
  this.fetchChartDataWithoutState(location.href, $selectedOption);
};

$(function() {
  var inputs = {
    insightsDiv:      $('#report-div'),
    reportsSelectBox: $('#reports'),
    resetButton: $('#reset'),
    refreshButton: $('#refresh'),
    removePaginationButton: $('#remove-pagination'),
    applyPaginationButton: $('#apply-pagination'),
    tableHelpers: $('#table-helpers'),
    filterDiv: $('#search-div'),
    paginatorDiv: $('#paginator-div'),
    chartContainer: $('#chart-container'),
    downloadLinks: $('.download-link')
  },
    reportLoader = new ReportLoader(inputs);
  reportLoader.init();
  reportLoader.bindEvents();
  reportLoader.populateInitialData();
});
