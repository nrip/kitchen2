<?php
declare(strict_types=1);
require_once __DIR__ . '/../../../src/bootstrap.php';

$path = trim(parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH), '/');
$route = preg_replace('#^api/v1/?#','',$path);
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$rid = request_id();

if ($route === 'health' && $method === 'GET') json_response(['success'=>true,'data'=>['service'=>'kitchen-food-service','version'=>APP_VERSION,'database'=>is_demo()?'demo-json':'mysql','time'=>now_iso()],'request_id'=>$rid]);

$provided = $_SERVER['HTTP_X_INTEGRATION_KEY'] ?? '';
$expected = envv('INTEGRATION_API_KEY', 'demo-integration-key');
if (!hash_equals($expected, $provided)) json_response(['success'=>false,'message'=>'Missing or invalid X-Integration-Key.','request_id'=>$rid],401);

if ($route === 'patients' && $method === 'GET') {
    $rows=$repo->all('patients'); $search=strtolower((string)($_GET['search']??'')); $external=(string)($_GET['external_id']??'');
    $rows=array_values(array_filter($rows,fn($p)=> (!$search || str_contains(strtolower($p['name'].' '.$p['hospital_no'].' '.$p['ward']),$search)) && (!$external || $p['external_id']===$external)));
    json_response(['success'=>true,'data'=>$rows,'request_id'=>$rid]);
}

$body = json_decode((string)file_get_contents('php://input'), true) ?: [];
if ($route === 'patients/upsert' && $method === 'POST') {
    if (!isset($body['external_id'],$body['source_system'],$body['name'])) json_response(['success'=>false,'message'=>'external_id, source_system, and name are required.','request_id'=>$rid],422);
    $row=$repo->upsertByExternal('patients',['hospital_no'=>$body['hospital_no']??'','name'=>$body['name'],'ward'=>$body['ward']??'','room'=>$body['room']??'','allergies'=>$body['allergies']??'Not supplied','clinical_notes'=>$body['clinical_notes']??''],$body['external_id'],$body['source_system']);
    json_response(['success'=>true,'data'=>$row,'message'=>'Patient snapshot upserted.','request_id'=>$rid]);
}
if ($route === 'clinicians/upsert' && $method === 'POST') {
    if (!isset($body['external_id'],$body['source_system'],$body['name'])) json_response(['success'=>false,'message'=>'external_id, source_system, and name are required.','request_id'=>$rid],422);
    $row=$repo->upsertByExternal('clinicians',['name'=>$body['name'],'specialty'=>$body['specialty']??''],$body['external_id'],$body['source_system']);
    json_response(['success'=>true,'data'=>$row,'message'=>'Clinician snapshot upserted.','request_id'=>$rid]);
}
if ($route === 'diet-orders' && $method === 'GET') {
    $rows=$repo->all('diet_orders'); $external=(string)($_GET['patient_external_id']??'');
    if ($external) { $patient=current(array_filter($repo->all('patients'),fn($p)=>$p['external_id']===$external)) ?: null; $rows=$patient?array_values(array_filter($rows,fn($o)=>(int)$o['patient_id'] === (int)$patient['id'])):[]; }
    json_response(['success'=>true,'data'=>$rows,'request_id'=>$rid]);
}
if ($route === 'diet-orders' && $method === 'POST') {
    foreach(['patient_external_id','source_system','diet_code','clinician_external_id','effective_from'] as $required) if (!isset($body[$required])) json_response(['success'=>false,'message'=>$required.' is required.','request_id'=>$rid],422);
    $p=current(array_filter($repo->all('patients'),fn($x)=>$x['external_id']===$body['patient_external_id'] && ($x['source_system']??'')===$body['source_system'])) ?: null;
    $c=current(array_filter($repo->all('clinicians'),fn($x)=>$x['external_id']===$body['clinician_external_id'] && ($x['source_system']??'')===$body['source_system'])) ?: null;
    $d=current(array_filter($repo->all('diet_types'),fn($x)=>$x['code']===$body['diet_code'])) ?: null;
    if (!$p || !$c || !$d) json_response(['success'=>false,'message'=>'Patient, clinician, and diet code must exist in the module snapshot.','request_id'=>$rid],422);
    $row=$repo->insert('diet_orders',['patient_id'=>$p['id'],'patient_name'=>$p['name'],'diet_code'=>$d['code'],'diet_name'=>$d['name'],'clinician_name'=>$c['name'],'effective_from'=>$body['effective_from'],'meal_texture'=>$body['meal_texture']??'Regular','calories'=>(int)($body['calories']??1800),'notes'=>$body['notes']??'','status'=>'active']);
    json_response(['success'=>true,'data'=>$row,'message'=>'Diet order created.','request_id'=>$rid],201);
}
if ($route === 'import/csv' && $method === 'POST') {
    $csv = $_FILES['file']['tmp_name'] ?? '';
    if (!$csv || !is_uploaded_file($csv)) json_response(['success'=>false,'message'=>'Upload a CSV file using the file field.','request_id'=>$rid],422);
    $handle=fopen($csv,'r'); $headers=fgetcsv($handle); $count=0;
    while(($values=fgetcsv($handle))!==false){$row=array_combine($headers,$values); if (($row['entity']??'')==='patient' && !empty($row['external_id'])) {$repo->upsertByExternal('patients',['hospital_no'=>$row['hospital_no']??'','name'=>$row['name']??'','ward'=>$row['ward']??'','room'=>$row['room']??'','allergies'=>$row['allergies']??'Not supplied','clinical_notes'=>$row['clinical_notes']??''],$row['external_id'],$row['source_system']??'CSV');$count++;}}
    fclose($handle); json_response(['success'=>true,'data'=>['rows_processed'=>$count],'message'=>'CSV import completed.','request_id'=>$rid]);
}
if ($route === 'export/daily-kitchen.csv' && $method === 'GET') {
    header('Content-Type: text/csv; charset=utf-8'); header('Content-Disposition: inline; filename="daily-kitchen.csv"');
    $out=fopen('php://output','w'); fputcsv($out,['tray_ref','patient','ward','meal_period','diet','status','scheduled_at']); foreach($repo->all('trays') as $t) fputcsv($out,[$t['tray_ref'],$t['patient_name'],$t['ward'],$t['meal_period'],$t['diet'],$t['status'],$t['scheduled_at']]); fclose($out); exit;
}
json_response(['success'=>false,'message'=>'Route not found.','request_id'=>$rid],404);
