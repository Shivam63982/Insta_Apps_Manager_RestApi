from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager

# -----------------------
# Employee Manager
# -----------------------
class EmployeeManager(BaseUserManager):
    def create_user(self, employee_id, password=None, **extra_fields):
        if not employee_id:
            raise ValueError("Employee ID is required")
        employee = self.model(employee_id=employee_id, **extra_fields)
        employee.set_password(password)
        employee.save(using=self._db)
        return employee

    def create_superuser(self, employee_id, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(employee_id, password, **extra_fields)

# -----------------------
# Custom Employee Model
# -----------------------
class Employee(AbstractBaseUser, PermissionsMixin):
    employee_id = models.PositiveIntegerField(unique=True)
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    instagram_apps = models.ManyToManyField(
        'InstagramApp',
        related_name='employees',
        blank=True,
        help_text="Assign one or more Instagram Apps to this employee"
    )

    objects = EmployeeManager()

    USERNAME_FIELD = 'employee_id'
    REQUIRED_FIELDS = ['name']

    def __str__(self):
        return f"{self.employee_id} - {self.name}"

# -----------------------
# Instagram App Model
# -----------------------
class InstagramApp(models.Model):
    name = models.CharField(max_length=100, blank=True)
    app_id = models.CharField(max_length=100, unique=True)
    access_token = models.TextField()
      # Friendly name for UI

    def __str__(self):
        return f"{self.name or self.app_id}"
