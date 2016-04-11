//= require spree/backend/jquery.tablesorter.min

function TableSorter(inputs) {
  this.$insightsTableList = inputs.$insightsTable;
  this.reportLoader = inputs.reportLoader;
  this.paginatorDiv = inputs.paginatorDiv;
}

TableSorter.prototype.bindEvents = function() {
  var _this = this;
  this.$insightsTableList.on('click', '#admin-insight .sortable-link', function() {
    event.preventDefault();
    var currentPage = _this.paginatorDiv.find('li.active a').html() - 1,
      noPagination = _this.reportLoader.removePaginationButton.closest('span').hasClass('hide'),
      requestPath = $(event.target).attr('href') + '&' + $('#filter-search').serialize() + '&page=' + currentPage + "&per_page=" + _this.reportLoader.pageSelector.find(':selected').attr('value') + '&no_pagination=' + noPagination;
    _this.reportLoader.requestUrl = requestPath;

    $.ajax({
      type: 'GET',
      url: requestPath,
      dataType: 'json',
      success: function(data) {
        _this.populateInsightsData(data);
      }
    });
  });
};

TableSorter.prototype.populateInsightsData = function(data) {
  this.reportLoader.populateInsightsData(data);
};

TableSorter.prototype.fetchSortedAttribute = function() {
  var attribute, sortOrder;
  if (this.$insightsTableList.find('.asc').length) {
    attribute = this.getSortedAttribute('asc');
    sortOrder = 'asc';
  } else if(this.$insightsTableList.find('.desc').length) {
    attribute = this.getSortedAttribute('desc');
    sortOrder = 'desc';
  }
  return [attribute, sortOrder];
};

TableSorter.prototype.getSortedAttribute = function(order) {
  return this.$insightsTableList.find(`.${order}`).data('attribute');
};
