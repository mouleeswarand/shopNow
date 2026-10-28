pipeline {
    agent any

    stages {
        stage('Verify source') {
            steps {
                sh '''
                    echo "ShopNow source downloaded successfully"
                    git log -1 --oneline
                    ls -la
                '''
            }
        }
    }
}
