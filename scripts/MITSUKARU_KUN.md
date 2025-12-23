# 環境構築手順書

本ドキュメントは、`/u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts` 配下のシェルスクリプトを使用した環境構築および起動手順について記載しています。

## 1. Miniconda のセットアップ

まず最初に Miniconda 環境を構築します。

```bash
cd /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts
source setup_miniconda_ubuntu.sh
```

## 2. No.1-Any2Pdf のセットアップ

Any2Pdf アプリケーションの環境構築を行います。

```bash
/bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/setup_no1_any2pdf.sh
```

## 3. No.1-Any2Pdf の起動

以下のコマンドでサービスを起動します。

```bash
/bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_any2pdf.sh
```

## 4. No.1-ChatOCI-Images のセットアップ

ChatOCI-Images アプリケーションの環境構築を行います。

```bash
/bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/setup_no1_chatoci_images.sh
```

### 設定ファイルの編集

**注意:** `setup_no1_chatoci_images.sh` の実行後、アプリケーションを起動する前に `.env` ファイルの設定が必要です。

#### 環境変数ファイルの作成
```bash
cd /u01/aipoc/No.1-ChatOCI-Images
vi .env
```

#### 主要な設定項目
`.env` ファイル内の以下の項目を設定してください。

```bash
# OCI 設定
OCI_CONFIG_FILE=~/.oci/config
OCI_PROFILE=DEFAULT
OCI_BUCKET=your-bucket-name
OCI_REGION=us-chicago-1
OCI_COMPARTMENT_OCID=ocid1.compartment.oc1..your-compartment-ocid

# Oracle Database設定
DB_USER=your-db-username
DB_PASSWORD=your-db-password
DB_DSN=your-oracle-db-dsn  # 完全なDSN文字列（例: host:port/service_name）
```

### 5. OCI 設定

#### OCI 設定ファイルの作成
`~/.oci/config` ファイルを作成し、必要な認証情報を記述します：
```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaa...
fingerprint=12:34:56:78:90:ab:cd:ef...
key_file=~/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..aaaaaaaa...
region=us-chicago-1
```

## 6. No.1-ChatOCI-Images の起動

設定完了後、以下のコマンドでサービスを起動します。

```bash
chmod +x /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_chatoci_images.sh
/bin/bash /u01/aipoc/No.1-ADB-SelectAI-Sidecar/scripts/start_no1_chatoci_images.sh
```
