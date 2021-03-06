{#
 # Copyright (c) 2020 Deciso B.V.
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or withoutmodification,
 # are permitted provided that the following conditions are met:
 #
 # 1. Redistributions of source code must retain the above copyright notice,
 #    this list of conditions and the following disclaimer.
 #
 # 2. Redistributions in binary form must reproduce the above copyright notice,
 #    this list of conditions and the following disclaimer in the documentation
 #    and/or other materials provided with the distribution.
 #
 # THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 # INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 # AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 # AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 # OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 #}

<script>
    $( document ).ready(function() {

      /**
       * jqtree expects a list + dict type structure, transform key value store into expected output
       * https://mbraak.github.io/jqTree/#general
       */
      function dict_to_tree(node, path) {
          let result = [];
          if ( path === undefined) {
              path = "";
          } else {
              path = path + ".";
          }
          for (key in node) {
              if (typeof node[key] === "function") {
                  continue;
              }
              let item_path = path + key;
              if (node[key] instanceof Object) {
                  result.push({
                      name: key,
                      id: item_path,
                      children: dict_to_tree(node[key], item_path)
                  });
              } else {
                  result.push({
                      name: key,
                      value: node[key],
                      id: item_path
                  });
              }
          }
          return result;
      }

      function update_tree(endpoint, target)
      {
          ajaxGet(endpoint, {}, function (data, status) {
              if (status == "success") {
                  let $tree = $(target);
                  if ($(target + ' > ul').length == 0) {
                      $tree.tree({
                          data: dict_to_tree(data),
                          autoOpen: false,
                          dragAndDrop: false,
                          selectable: false,
                          closedIcon: $('<i class="fa fa-plus-square-o"></i>'),
                          openedIcon: $('<i class="fa fa-minus-square-o"></i>'),
                          onCreateLi: function(node, $li) {
                              if (node.value !== undefined) {
                                  $li.find('.jqtree-element').append(
                                      '&nbsp; <strong>:</strong> &nbsp;' + node.value
                                  );
                              }
                          }
                      });
                      // initial view, collapse first level if there's only one node
                      if (Object.keys(data).length == 1) {
                          for (key in data) {
                              $tree.tree('openNode', $tree.tree('getNodeById', key));
                          }
                      }
                  } else {
                      let curent_state = $tree.tree('getState');
                      $tree.tree('loadData', dict_to_tree(data));
                      $tree.tree('setState', curent_state);
                  }
              }
          });
      }

      $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
          $(".tab-icon").removeClass("fa-refresh");
          if ($("#"+e.target.id).data('tree-target') !== undefined) {
              $("#"+e.target.id).unbind('click').click(function(){
                  update_tree($("#"+e.target.id).data('tree-endpoint'), "#" + $("#"+e.target.id).data('tree-target'));
              });
              if (!$("#"+e.target.id).hasClass("event-hooked")) {
                  $("#"+e.target.id).addClass("event-hooked")
                  $("#"+e.target.id).click();
              }
              $("#"+e.target.id).find(".tab-icon").addClass("fa-refresh");
          }
      });

      // update history on tab state and implement navigation
      let selected_tab = window.location.hash != "" ? window.location.hash : "#interfaces";
      $('a[href="' +selected_tab + '"]').click();
      $('.nav-tabs a').on('shown.bs.tab', function (e) {
          history.pushState(null, null, e.target.hash);
      });
      $(window).on('hashchange', function(e) {
          $('a[href="' + window.location.hash + '"]').click()
      });
    });
</script>

<link rel="stylesheet" type="text/css" href="{{ cache_safe(theme_file_or_default('/css/jqtree.css', ui_theme|default('opnsense'))) }}">
<script src="{{ cache_safe('/ui/js/tree.jquery.min.js') }}"></script>

<ul class="nav nav-tabs" data-tabs="tabs" id="maintabs">
    <li>
      <a data-toggle="tab" href="#interfaces" id="interfaces_tab"
         data-tree-target="interfacesTree"
         data-tree-endpoint="/api/diagnostics/interface/getInterfaceStatistics">
          {{ lang._('Interfaces') }} <i class="fa tab-icon "></i>
      </a>
    </li>
    <li>
      <a data-toggle="tab" href="#protocol" id="protocol_tab"
         data-tree-target="protocolTree"
         data-tree-endpoint="/api/diagnostics/interface/getProtocolStatistics">
           {{ lang._('Protocol') }} <i class="fa tab-icon "></i>
      </a>
    </li>
    <li>
      <a data-toggle="tab" href="#sockets" id="sockets_tab"
         data-tree-target="socketsTree"
         data-tree-endpoint="/api/diagnostics/interface/getSocketStatistics">
          {{ lang._('Sockets') }} <i class="fa tab-icon "></i>
      </a>
    </li>
</ul>
<div class="tab-content content-box">
    <div id="interfaces" class="tab-pane fade in active">
      <div class="row">
          <section class="col-xs-12">
              <div class="content-box">
                <div style="padding: 5px; overflow-y: scroll; height:400px;" id="interfacesTree"></div>
              </div>
          </section>
      </div>
    </div>
    <div id="protocol" class="tab-pane fade in active">
        <div class="row">
            <section class="col-xs-12">
                <div class="content-box">
                  <div style="padding: 5px; overflow-y: scroll; height:400px;" id="protocolTree"></div>
                </div>
            </section>
        </div>
    </div>
    <div id="sockets" class="tab-pane fade in active">
      <div class="row">
          <section class="col-xs-12">
              <div class="content-box">
                <div style="padding: 5px; overflow-y: scroll; height:400px;" id="socketsTree"></div>
              </div>
          </section>
      </div>
    </div>
</div>
