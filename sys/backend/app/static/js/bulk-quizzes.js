(function () {
  "use strict";

  const app = document.getElementById("bulk-quiz-app");
  if (!app) return;

  const categories = JSON.parse(app.dataset.categories || "[]");

  // State
  let rows = [];
  let generatedQuizzes = [];
  let phase = "config"; // config | review
  let rowIdCounter = 0;

  // DOM references
  const configPhase = document.getElementById("config-phase");
  const reviewPhase = document.getElementById("review-phase");
  const categoryRowsEl = document.getElementById("category-rows");
  const addRowBtn = document.getElementById("add-row-btn");
  const generateBtn = document.getElementById("generate-btn");
  const saveBtn = document.getElementById("save-btn");
  const backBtn = document.getElementById("back-btn");
  const regenerateBtn = document.getElementById("regenerate-btn");
  const summaryEl = document.getElementById("summary");
  const reviewCountEl = document.getElementById("review-count");
  const reviewTableBody = document.getElementById("review-table-body");
  const loadingOverlay = document.getElementById("loading-overlay");
  const loadingText = document.getElementById("loading-text");
  const errorDisplay = document.getElementById("error-display");
  const errorMessage = document.getElementById("error-message");

  // Initialize with one row
  addRow();

  // Set default release date to today
  const today = new Date().toISOString().split("T")[0];
  document.getElementById("release-date").value = today;

  // Event listeners
  addRowBtn.addEventListener("click", addRow);
  generateBtn.addEventListener("click", handleGenerate);
  saveBtn.addEventListener("click", handleSave);
  backBtn.addEventListener("click", goBackToConfig);
  regenerateBtn.addEventListener("click", handleGenerate);

  // Beforeunload warning
  window.addEventListener("beforeunload", function (e) {
    if (generatedQuizzes.length > 0 && phase === "review") {
      e.preventDefault();
      e.returnValue = "";
    }
  });

  function addRow() {
    const id = rowIdCounter++;
    rows.push({ id: id, categoryId: "", count: 3 });
    renderRows();
    updateSummary();
  }

  function removeRow(id) {
    rows = rows.filter(function (r) {
      return r.id !== id;
    });
    if (rows.length === 0) addRow();
    renderRows();
    updateSummary();
  }

  function renderRows() {
    categoryRowsEl.innerHTML = "";
    rows.forEach(function (row) {
      var div = document.createElement("div");
      div.className =
        "flex items-center gap-3 p-3 bg-gray-50 rounded-lg";
      div.dataset.rowId = row.id;

      // Category select
      var select = document.createElement("select");
      select.className =
        "flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none text-sm";
      select.innerHTML = '<option value="">カテゴリを選択...</option>';
      var usedIds = rows
        .filter(function (r) {
          return r.id !== row.id && r.categoryId;
        })
        .map(function (r) {
          return r.categoryId;
        });
      categories.forEach(function (cat) {
        var opt = document.createElement("option");
        opt.value = cat.id;
        opt.textContent = cat.name;
        if (usedIds.indexOf(cat.id) !== -1) {
          opt.disabled = true;
          opt.textContent += " (使用済み)";
        }
        if (cat.id === row.categoryId) opt.selected = true;
        select.appendChild(opt);
      });
      select.addEventListener("change", function () {
        row.categoryId = this.value;
        renderRows();
        updateSummary();
      });

      // Count input
      var countInput = document.createElement("input");
      countInput.type = "number";
      countInput.min = "1";
      countInput.max = "20";
      countInput.value = row.count;
      countInput.className =
        "w-24 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none text-sm text-center";
      countInput.addEventListener("change", function () {
        var val = parseInt(this.value) || 1;
        if (val < 1) val = 1;
        if (val > 20) val = 20;
        this.value = val;
        row.count = val;
        updateSummary();
      });

      // Count label
      var countLabel = document.createElement("span");
      countLabel.className = "text-sm text-gray-500";
      countLabel.textContent = "件";

      // Remove button
      var removeBtn = document.createElement("button");
      removeBtn.type = "button";
      removeBtn.className =
        "text-red-400 hover:text-red-600 transition-colors p-1";
      removeBtn.innerHTML =
        '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>';
      removeBtn.addEventListener("click", function () {
        removeRow(row.id);
      });

      div.appendChild(select);
      div.appendChild(countInput);
      div.appendChild(countLabel);
      div.appendChild(removeBtn);
      categoryRowsEl.appendChild(div);
    });
  }

  function updateSummary() {
    var validRows = rows.filter(function (r) {
      return r.categoryId;
    });
    var totalCount = rows.reduce(function (sum, r) {
      return sum + r.count;
    }, 0);
    summaryEl.textContent =
      validRows.length + "カテゴリ / 合計" + totalCount + "件";
  }

  function showError(msg) {
    errorMessage.textContent = msg;
    errorDisplay.classList.remove("hidden");
    setTimeout(function () {
      errorDisplay.classList.add("hidden");
    }, 5000);
  }

  function hideError() {
    errorDisplay.classList.add("hidden");
  }

  function showLoading(text) {
    loadingText.textContent = text;
    loadingOverlay.classList.remove("hidden");
  }

  function hideLoading() {
    loadingOverlay.classList.add("hidden");
  }

  function validateConfig() {
    var validRows = rows.filter(function (r) {
      return r.categoryId;
    });
    if (validRows.length === 0) {
      showError("カテゴリを1つ以上選択してください");
      return false;
    }
    if (validRows.length !== rows.length) {
      showError("全ての行でカテゴリを選択してください");
      return false;
    }
    var totalCount = rows.reduce(function (sum, r) {
      return sum + r.count;
    }, 0);
    if (totalCount > 50) {
      showError("合計件数は50件以下にしてください");
      return false;
    }
    var releaseDate = document.getElementById("release-date").value;
    if (!releaseDate) {
      showError("公開日を設定してください");
      return false;
    }
    return true;
  }

  function buildGeneratePayload() {
    return {
      rows: rows.map(function (r) {
        var cat = categories.find(function (c) {
          return c.id === r.categoryId;
        });
        return {
          category_id: r.categoryId,
          category_name: cat ? cat.name : "",
          count: r.count,
        };
      }),
    };
  }

  function handleGenerate() {
    hideError();
    if (!validateConfig()) return;

    showLoading("AIがクイズを生成中...");
    generateBtn.disabled = true;

    fetch("/admin/quizzes/bulk/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(buildGeneratePayload()),
    })
      .then(function (res) {
        return res.json();
      })
      .then(function (data) {
        hideLoading();
        generateBtn.disabled = false;
        if (!data.success) {
          showError(data.error || "生成に失敗しました");
          return;
        }
        generatedQuizzes = data.data.quizzes || [];
        if (generatedQuizzes.length === 0) {
          showError("クイズが生成されませんでした");
          return;
        }
        showReviewPhase();
      })
      .catch(function (err) {
        hideLoading();
        generateBtn.disabled = false;
        showError("通信エラーが発生しました");
      });
  }

  function showReviewPhase() {
    phase = "review";
    configPhase.classList.add("hidden");
    reviewPhase.classList.remove("hidden");
    renderReviewTable();
  }

  function goBackToConfig() {
    phase = "config";
    reviewPhase.classList.add("hidden");
    configPhase.classList.remove("hidden");
  }

  function renderReviewTable() {
    reviewCountEl.textContent = generatedQuizzes.length + "件のクイズ";
    reviewTableBody.innerHTML = "";
    generatedQuizzes.forEach(function (quiz, idx) {
      var tr = document.createElement("tr");
      tr.className = "border-b border-gray-100 hover:bg-gray-50";

      var tdCat = document.createElement("td");
      tdCat.className = "py-3 px-4 text-sm text-gray-600";
      tdCat.textContent = quiz.category_name;

      var tdTitle = document.createElement("td");
      tdTitle.className = "py-3 px-4 text-sm font-medium text-gray-900";
      tdTitle.textContent = quiz.title;

      var tdDesc = document.createElement("td");
      tdDesc.className = "py-3 px-4 text-sm text-gray-600";
      tdDesc.textContent = quiz.description;

      var tdAction = document.createElement("td");
      tdAction.className = "py-3 px-4";
      var removeBtn = document.createElement("button");
      removeBtn.type = "button";
      removeBtn.className =
        "text-red-400 hover:text-red-600 transition-colors text-sm";
      removeBtn.textContent = "削除";
      removeBtn.addEventListener("click", function () {
        generatedQuizzes.splice(idx, 1);
        renderReviewTable();
        if (generatedQuizzes.length === 0) {
          goBackToConfig();
        }
      });
      tdAction.appendChild(removeBtn);

      tr.appendChild(tdCat);
      tr.appendChild(tdTitle);
      tr.appendChild(tdDesc);
      tr.appendChild(tdAction);
      reviewTableBody.appendChild(tr);
    });
  }

  function handleSave() {
    hideError();
    if (generatedQuizzes.length === 0) {
      showError("保存するクイズがありません");
      return;
    }

    var releaseDate = document.getElementById("release-date").value;
    var status = document.getElementById("quiz-status").value;

    showLoading("保存中...");
    saveBtn.disabled = true;

    fetch("/admin/quizzes/bulk/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        release_date: releaseDate,
        status: status,
        quizzes: generatedQuizzes.map(function (q) {
          return {
            category_id: q.category_id,
            title: q.title,
            description: q.description,
          };
        }),
      }),
    })
      .then(function (res) {
        return res.json();
      })
      .then(function (data) {
        hideLoading();
        saveBtn.disabled = false;
        if (!data.success) {
          showError(data.error || "保存に失敗しました");
          return;
        }
        // Clear state to prevent beforeunload warning
        generatedQuizzes = [];
        window.location.href = data.data.redirect_url || "/admin/quizzes";
      })
      .catch(function (err) {
        hideLoading();
        saveBtn.disabled = false;
        showError("通信エラーが発生しました");
      });
  }
})();
