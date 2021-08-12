//= require spree/backend/spree_admin_insights/paginator

function Searcher(inputs, reportLoader) {
  this.$insightsTableList = inputs.insightsDiv;
  this.$filters = inputs.filterDiv;
  this.$quickSearchForm = this.$filters.find('#quick-search');
  this.tableSorter = inputs.tableSorterObject;
  this.reportLoader = reportLoader;
  this.$filterForm = null;
  this.$searchLabelsContainer = this.$filters.find('.table-active-filters');
}

Searcher.prototype.bindEvents = function(data) {
  var _this = this;
  this.$searchLabelsContainer.on("click", ".js-delete-filter", function() {
    _this.$quickSearchForm[0].reset();
    $(this).parent().hide();
  });
};

Searcher.prototype.refreshSearcher = function($selectedInsight, data) {
  var requestPath = $selectedInsight.data('url'),
    _this = this;

  _this.$filters.removeClass('hide');
  _this.addSearchForm(data);
  _this.setFormActions(_this.$quickSearchForm, requestPath);
  _this.setFormActions(_this.$filterForm, requestPath);

  _this.$filterForm.on('submit', function() {
   var paginated = !_this.reportLoader.removePaginationButton.closest('span').hasClass('hide');
   _this.addSearchStatus();
   $.ajax({
     type: "GET",
     url: _this.$filterForm.attr('action'),
     data: _this.$filterForm.serialize() + "&per_page=" + _this.reportLoader.pageSelector.find(':selected').attr('value') + '&paginate=' + paginated,
     dataType: 'json',
     success: function(data) {
      _this.clearFormFields();
      _this.reportLoader.requestUrl = this.url;
      _this.populateInsightsData(data);
      _this.reportLoader.paginatorObject.refreshPaginator(data);
     }
   });
   return false;
  });
};

Searcher.prototype.addSearchStatus = function () {
  var filtersContainer = $(".js-filters");
  filtersContainer.empty();
  $(".js-filterable").each(function() {
   var $this = $(this);

    if ($this.val()) {
      var ransack_value, filter;
      var ransack_field = $this.attr("id");
      var label = $('label[for="' + ransack_field + '"]');
      if ($this.is("select")) {
        ransack_value = $this.find('option:selected').text();
      } else {
        ransack_value = $this.val();
      }

      label = label.text() + ': ' + ransack_value;
      filter = '<span class="js-filter badge badge-secondary" data-ransack-field="' + ransack_field + '">' + label + '<i class="icon icon-cancel ml-2 js-delete-filter"></i></span>';

      filtersContainer.append(filter).show();
    }
  });
};

Searcher.prototype.addSearchForm = function(data) {
  this.$filters.find('#table-filter').empty().append($(tmpl('search-tmpl', data)));
  this.$filterForm = this.$filters.find('#filter-search');
};

Searcher.prototype.setFormActions = function($form, path) {
  $form.attr("method", "get");
  $form.attr("action", path);
};

Searcher.prototype.populateInsightsData = function(data) {
  this.reportLoader.populateInsightsData(data);
};

Searcher.prototype.clearFormFields = function() {
  this.$filters.find('.filter-well').slideUp();
};

Searcher.prototype.fillFormFields = function(searchedFields) {
  $.each(Object.keys(searchedFields), function() {
    $('#search_' + this).val(searchedFields[this]);
  });
  this.addSearchStatus();
};

Searcher.prototype.clearSearchFields = function() {
  this.$quickSearchForm[0].reset();
  var filtersContainer = $(".js-filters");
  filtersContainer.empty();
};
