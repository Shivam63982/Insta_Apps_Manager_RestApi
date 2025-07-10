from rest_framework import serializers
from .models import Employee, InstagramApp

class EmployeeLoginSerializer(serializers.Serializer):
    employee_id = serializers.IntegerField()
    password = serializers.CharField(write_only=True)

class InstagramAppSerializer(serializers.ModelSerializer):
    class Meta:
        model = InstagramApp
        fields = ['id', 'app_id', 'access_token', 'name','employees',]
from rest_framework import serializers
from .models import Employee, InstagramApp

# Used inside InstagramAppSerializer to show basic employee info
class EmployeeMiniSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = ['employee_id', 'name']

# Login serializer used for authentication
class EmployeeLoginSerializer(serializers.Serializer):
    employee_id = serializers.IntegerField()
    password = serializers.CharField(write_only=True)

# Main InstagramApp serializer with nested employee info
class InstagramAppSerializer(serializers.ModelSerializer):
    # employees = EmployeeMiniSerializer(many=True, read_only=True)

    class Meta:
        model = InstagramApp
        fields = ['id','name', 'app_id', 'access_token']
