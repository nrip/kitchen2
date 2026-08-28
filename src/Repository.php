<?php
declare(strict_types=1);

final class Repository {
    private ?PDO $pdo = null;
    private string $jsonPath;
    private array $data = [];

    public function __construct(string $jsonPath) {
        $this->jsonPath = $jsonPath;
        $host = envv('KITCHEN_DB_HOST');
        if ($host) {
            $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, envv('KITCHEN_DB_PORT', '3306'), envv('KITCHEN_DB_NAME', 'kitchen_food'));
            try {
                $this->pdo = new PDO($dsn, envv('KITCHEN_DB_USER', 'root'), envv('KITCHEN_DB_PASS', ''), [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
            } catch (Throwable $e) {
                if (envv('KITCHEN_PRODUCTION', '0') === '1') throw new RuntimeException('Configured KitchenFlow database is unavailable.', 0, $e);
                $this->pdo = null;
            }
        }
        if (!$this->pdo) {
            if (envv('KITCHEN_PRODUCTION', '0') === '1') throw new RuntimeException('KitchenFlow production database is not configured.');
            $this->loadDemo();
        }
    }

    private function loadDemo(): void {
        if (!is_file($this->jsonPath)) {
            $this->data = [
                'patients' => [
                    ['id'=>1,'external_id'=>'PAT-1007','source_system'=>'HIS-DEMO','hospital_no'=>'MRN-1007','name'=>'Aarav Mehta','ward'=>'Ward 3B','room'=>'312','allergies'=>'Peanuts; shellfish','clinical_notes'=>'Post-operative recovery; monitor protein intake'],
                    ['id'=>2,'external_id'=>'PAT-1012','source_system'=>'HIS-DEMO','hospital_no'=>'MRN-1012','name'=>'Maya Iyer','ward'=>'ICU','room'=>'ICU-04','allergies'=>'Lactose','clinical_notes'=>'Diabetic meal plan required'],
                    ['id'=>3,'external_id'=>'PAT-1021','source_system'=>'HIS-DEMO','hospital_no'=>'MRN-1021','name'=>'Rohan Das','ward'=>'Ward 2A','room'=>'208','allergies'=>'None reported','clinical_notes'=>'Renal diet under review'],
                ],
                'clinicians' => [
                    ['id'=>1,'external_id'=>'DOC-204','name'=>'Dr. Nisha Shah','specialty'=>'Internal Medicine'],
                    ['id'=>2,'external_id'=>'DOC-311','name'=>'Dr. Vikram Rao','specialty'=>'Nephrology'],
                ],
                'diet_types' => [
                    ['id'=>1,'code'=>'REG','name'=>'Regular balanced','category'=>'Standard','therapeutic'=>0],
                    ['id'=>2,'code'=>'DM','name'=>'Diabetic / controlled carbohydrate','category'=>'Therapeutic','therapeutic'=>1],
                    ['id'=>3,'code'=>'RENAL','name'=>'Renal low sodium','category'=>'Therapeutic','therapeutic'=>1],
                    ['id'=>4,'code'=>'SOFT','name'=>'Soft / easy chew','category'=>'Texture modified','therapeutic'=>0],
                    ['id'=>5,'code'=>'VEG','name'=>'Vegetarian Indian','category'=>'Cultural preference','therapeutic'=>0],
                ],
                'diet_orders' => [
                    ['id'=>1,'patient_id'=>1,'patient_name'=>'Aarav Mehta','diet_code'=>'SOFT','diet_name'=>'Soft / easy chew','clinician_name'=>'Dr. Nisha Shah','effective_from'=>date('Y-m-d'),'meal_texture'=>'Soft','calories'=>1900,'notes'=>'High protein; avoid peanuts and shellfish','status'=>'active'],
                    ['id'=>2,'patient_id'=>2,'patient_name'=>'Maya Iyer','diet_code'=>'DM','diet_name'=>'Diabetic / controlled carbohydrate','clinician_name'=>'Dr. Nisha Shah','effective_from'=>date('Y-m-d'),'meal_texture'=>'Regular','calories'=>1600,'notes'=>'No added sugar; lactose-free','status'=>'active'],
                    ['id'=>3,'patient_id'=>3,'patient_name'=>'Rohan Das','diet_code'=>'RENAL','diet_name'=>'Renal low sodium','clinician_name'=>'Dr. Vikram Rao','effective_from'=>date('Y-m-d', strtotime('+1 day')),'meal_texture'=>'Regular','calories'=>1800,'notes'=>'Low sodium; fluid limit 1.5 L','status'=>'draft'],
                ],
                'menus' => [
                    ['id'=>1,'menu_date'=>date('Y-m-d'),'meal_period'=>'Lunch','title'=>'Heart-smart lunch','status'=>'Published','items'=>'Grilled herb chicken|Brown rice|Steamed vegetables|Low-fat curd','calories'=>620,'protein_g'=>38,'carbs_g'=>72,'fat_g'=>16],
                    ['id'=>2,'menu_date'=>date('Y-m-d'),'meal_period'=>'Dinner','title'=>'Vegetarian comfort dinner','status'=>'Published','items'=>'Moong dal|Phulka|Lauki sabzi|Fruit bowl','calories'=>510,'protein_g'=>22,'carbs_g'=>78,'fat_g'=>10],
                    ['id'=>3,'menu_date'=>date('Y-m-d', strtotime('+1 day')),'meal_period'=>'Breakfast','title'=>'Diabetic breakfast','status'=>'Planning','items'=>'Vegetable oats|Boiled egg|Unsweetened tea','calories'=>360,'protein_g'=>19,'carbs_g'=>44,'fat_g'=>12],
                ],
                'trays' => [
                    ['id'=>1,'tray_ref'=>'TRAY-24001','patient_name'=>'Aarav Mehta','ward'=>'Ward 3B','meal_period'=>'Breakfast','status'=>'Delivered','diet'=>'SOFT','scheduled_at'=>date('Y-m-d').' 08:00'],
                    ['id'=>2,'tray_ref'=>'TRAY-24002','patient_name'=>'Maya Iyer','ward'=>'ICU','meal_period'=>'Breakfast','status'=>'Assembled','diet'=>'DM','scheduled_at'=>date('Y-m-d').' 08:00'],
                    ['id'=>3,'tray_ref'=>'TRAY-24003','patient_name'=>'Rohan Das','ward'=>'Ward 2A','meal_period'=>'Lunch','status'=>'Planned','diet'=>'RENAL','scheduled_at'=>date('Y-m-d').' 12:30'],
                    ['id'=>4,'tray_ref'=>'TRAY-24004','patient_name'=>'Aarav Mehta','ward'=>'Ward 3B','meal_period'=>'Lunch','status'=>'Dispatched','diet'=>'SOFT','scheduled_at'=>date('Y-m-d').' 12:30'],
                ],
                'ingredients' => [
                    ['id'=>1,'sku'=>'ING-001','name'=>'Brown rice','unit'=>'kg','on_hand'=>18.5,'reorder_level'=>10,'expiry_date'=>date('Y-m-d', strtotime('+90 days')),'category'=>'Grains'],
                    ['id'=>2,'sku'=>'ING-002','name'=>'Low-fat curd','unit'=>'litre','on_hand'=>7.2,'reorder_level'=>12,'expiry_date'=>date('Y-m-d', strtotime('+3 days')),'category'=>'Dairy'],
                    ['id'=>3,'sku'=>'ING-003','name'=>'Moong dal','unit'=>'kg','on_hand'=>25,'reorder_level'=>8,'expiry_date'=>date('Y-m-d', strtotime('+120 days')),'category'=>'Pulses'],
                    ['id'=>4,'sku'=>'ING-004','name'=>'Seasonal vegetables','unit'=>'kg','on_hand'=>42,'reorder_level'=>20,'expiry_date'=>date('Y-m-d', strtotime('+5 days')),'category'=>'Produce'],
                    ['id'=>5,'sku'=>'ING-005','name'=>'Lactose-free milk','unit'=>'litre','on_hand'=>4,'reorder_level'=>8,'expiry_date'=>date('Y-m-d', strtotime('+4 days')),'category'=>'Special diet'],
                ],
                'wastage' => [
                    ['id'=>1,'ingredient'=>'Seasonal vegetables','quantity'=>2.5,'unit'=>'kg','reason'=>'Preparation trim','recorded_at'=>date('Y-m-d').' 09:10','recorded_by'=>'Kitchen Supervisor'],
                    ['id'=>2,'ingredient'=>'Low-fat curd','quantity'=>0.8,'unit'=>'litre','reason'=>'Expired / temperature breach','recorded_at'=>date('Y-m-d', strtotime('-1 day')).' 17:40','recorded_by'=>'Storekeeper'],
                ],
                'consumption' => [
                    ['id'=>1,'tray_ref'=>'TRAY-24001','patient_name'=>'Aarav Mehta','status'=>'Partially consumed','consumed_percent'=>60,'recorded_at'=>date('Y-m-d').' 09:05'],
                ],
            ];
            $this->saveDemo();
        } else $this->data = json_decode((string)file_get_contents($this->jsonPath), true) ?: [];
    }

    private function saveDemo(): void {
        if (!is_dir(dirname($this->jsonPath))) mkdir(dirname($this->jsonPath), 0775, true);
        file_put_contents($this->jsonPath, json_encode($this->data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES), LOCK_EX);
    }

    public function all(string $table): array {
        if ($this->pdo) return $this->pdo->query("SELECT * FROM `$table` ORDER BY id DESC")->fetchAll();
        return $this->data[$table] ?? [];
    }

    public function find(string $table, int $id): ?array {
        foreach ($this->all($table) as $row) if ((int)($row['id'] ?? 0) === $id) return $row;
        return null;
    }

    public function insert(string $table, array $row): array {
        if ($this->pdo) {
            $keys = array_keys($row); $cols = implode(',', array_map(fn($k)=>"`$k`", $keys)); $marks = implode(',', array_fill(0, count($keys), '?'));
            $stmt = $this->pdo->prepare("INSERT INTO `$table` ($cols) VALUES ($marks)"); $stmt->execute(array_values($row)); $row['id'] = (int)$this->pdo->lastInsertId(); return $row;
        }
        $ids = array_map(fn($r)=>(int)($r['id'] ?? 0), $this->data[$table] ?? []); $row['id'] = $ids ? max($ids) + 1 : 1; $this->data[$table][] = $row; $this->saveDemo(); return $row;
    }

    public function update(string $table, int $id, array $changes): ?array {
        if ($this->pdo) {
            $sets = implode(',', array_map(fn($k)=>"`$k` = ?", array_keys($changes))); $stmt = $this->pdo->prepare("UPDATE `$table` SET $sets WHERE id = ?"); $stmt->execute([...array_values($changes), $id]); return $this->find($table, $id);
        }
        foreach ($this->data[$table] ?? [] as $index => $row) {
            if ((int)($row['id'] ?? 0) === $id) {
                $this->data[$table][$index] = array_merge($row, $changes);
                $this->saveDemo();
                return $this->data[$table][$index];
            }
        }
        return null;
    }

    public function dashboard(): array {
        $orders = $this->all('diet_orders'); $trays = $this->all('trays'); $ingredients = $this->all('ingredients');
        $low = array_filter($ingredients, fn($i)=>(float)$i['on_hand'] <= (float)$i['reorder_level']);
        return ['active_orders'=>count(array_filter($orders, fn($o)=>($o['status'] ?? '')==='active')), 'trays_today'=>count($trays), 'delivered'=>count(array_filter($trays, fn($t)=>in_array($t['status'] ?? '', ['Delivered','Consumed']))), 'low_stock'=>count($low), 'wastage_total'=>array_sum(array_map(fn($w)=>(float)$w['quantity'], $this->all('wastage')))];
    }

    public function upsertByExternal(string $table, array $row, string $externalId, string $source): array {
        if ($this->pdo) {
            $stmt = $this->pdo->prepare("SELECT * FROM `$table` WHERE external_id = ? AND source_system = ? LIMIT 1"); $stmt->execute([$externalId, $source]); $existing = $stmt->fetch();
        } else $existing = current(array_filter($this->data[$table] ?? [], fn($r)=>($r['external_id'] ?? '')===$externalId && ($r['source_system'] ?? '')===$source)) ?: null;
        return $existing ? ($this->update($table, (int)$existing['id'], $row) ?? $existing) : $this->insert($table, array_merge($row, ['external_id'=>$externalId, 'source_system'=>$source]));
    }
}
