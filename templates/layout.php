<?php
function layout_start(string $title, string $active = 'dashboard'): void { ?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($title) ?> · <?= e(APP_NAME) ?></title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="/assets/css/app.css" rel="stylesheet">
</head>
<body>
<div class="app-shell">
<aside class="sidebar">
  <div class="brand"><div class="brand-mark"><i class="bi bi-egg-fried"></i></div><div><strong>KitchenFlow</strong><small>Hospital food service</small></div></div>
  <div class="workspace-label">OPERATIONS</div>
  <nav class="nav flex-column gap-1">
    <?php $items=[['dashboard','speedometer2','Dashboard'],['diet-orders','clipboard2-pulse','Diet orders'],['menus','calendar3','Menus & nutrition'],['trays','box-seam','Tray service'],['inventory','boxes','Inventory'],['wastage','recycle','Wastage control']]; foreach($items as [$key,$icon,$label]): ?>
      <a class="nav-link <?= $active===$key?'active':'' ?>" href="/?page=<?= $key ?>"><i class="bi bi-<?= $icon ?>"></i><span><?= e($label) ?></span></a>
    <?php endforeach; ?>
  </nav>
  <div class="workspace-label mt-4">INTEGRATION</div>
  <nav class="nav flex-column gap-1">
    <a class="nav-link <?= $active==='widget'?'active':'' ?>" href="/widget/diet-order.php"><i class="bi bi-code-square"></i><span>Embedded widget</span></a>
    <a class="nav-link" href="/api/v1/health" target="_blank"><i class="bi bi-plug"></i><span>API health</span></a>
  </nav>
  <div class="sidebar-footer"><div class="mini-avatar">KS</div><div><strong>Kitchen Supervisor</strong><small>Operations role</small></div><i class="bi bi-three-dots ms-auto"></i></div>
</aside>
<main class="main-content">
<header class="topbar"><div><span class="eyebrow">HOSPITAL FOOD SERVICES</span><h1><?= e($title) ?></h1></div><div class="top-actions"><span class="demo-pill"><i class="bi bi-circle-fill"></i> <?= is_demo() ? 'Preview data' : 'MySQL connected' ?></span><button class="icon-btn" title="Notifications"><i class="bi bi-bell"></i><span class="notification-dot"></span></button><div class="avatar">KS</div></div></header>
<?php if (!empty($_SESSION['flash'])): ?><div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><?= e($_SESSION['flash']); unset($_SESSION['flash']); ?><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div><?php endif; ?>
<?php }
function layout_end(): void { ?>
</main></div>
<script src="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="/assets/js/app.js"></script>
</body></html>
<?php }
function status_badge(string $status): string { $map=['active'=>'success','Active'=>'success','Delivered'=>'success','Consumed'=>'success','Published'=>'success','Assembled'=>'warning','Planning'=>'info','Planned'=>'secondary','Dispatched'=>'primary','draft'=>'secondary','Draft'=>'secondary','Low stock'=>'danger','Refused'=>'danger','Cancelled'=>'danger']; $class=$map[$status]??'secondary'; return '<span class="status-badge '.$class.'"><span></span>'.e($status).'</span>'; }
function stat_card(string $label, string $value, string $icon, string $tone, string $meta=''): void { echo '<div class="stat-card"><div class="stat-icon '.$tone.'"><i class="bi bi-'.$icon.'"></i></div><div><div class="stat-label">'.e($label).'</div><div class="stat-value">'.e($value).'</div>'.($meta?'<div class="stat-meta">'.e($meta).'</div>':'').'</div></div>'; }
