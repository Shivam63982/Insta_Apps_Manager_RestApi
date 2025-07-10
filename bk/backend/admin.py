# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from .models import Employee, InstagramApp

# class EmployeeAdmin(UserAdmin):
#     model = Employee
#     list_display = ('employee_id', 'name', 'is_staff', 'is_superuser')
#     search_fields = ('employee_id', 'name')
#     ordering = ('employee_id',)

#     fieldsets = (
#         (None, {'fields': ('employee_id', 'name', 'password')}),
#         ('Permissions', {'fields': ('is_staff', 'is_superuser', 'groups', 'user_permissions')}),
#     )

#     add_fieldsets = (
#         (None, {
#             'classes': ('wide',),
#             'fields': ('employee_id', 'name', 'password1', 'password2', 'is_staff', 'is_superuser')}
#         ),
#     )

# admin.site.register(Employee, EmployeeAdmin)
# admin.site.register(InstagramApp)



# from django.contrib import admin
# from .models import Employee, InstagramApp
# from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

# class EmployeeAdmin(BaseUserAdmin):
#     model = Employee
#     list_display = ('employee_id', 'name', 'is_staff', 'is_active')
#     list_filter = ('is_staff', 'is_superuser', 'is_active')
#     search_fields = ('employee_id', 'name')
#     ordering = ('employee_id',)

#     fieldsets = (
#         (None, {'fields': ('employee_id', 'password')}),
#         ('Personal Info', {'fields': ('name',)})
#         ,
#         ('Assigned Apps', {'fields': ('instagram_apps',)}),
#         ('Permissions', {
#             'fields': (
#                 'is_staff', 'is_superuser', 'is_active', 'groups', 'user_permissions'
#             )
#         })
#     )

#     add_fieldsets = (
#         (None, {
#             'classes': ('wide',),
#             'fields': (
#                 'employee_id', 'name', 'password1', 'password2',
#                 'is_staff', 'is_superuser', 'is_active', 'instagram_apps'
#             ),
#         }),
#     )

#     filter_horizontal = ('instagram_apps', 'groups', 'user_permissions')

# class InstagramAppAdmin(admin.ModelAdmin):
#     list_display = ('name', 'app_id')
#     search_fields = ('name', 'app_id')

# admin.site.register(Employee, EmployeeAdmin)
# admin.site.register(InstagramApp, InstagramAppAdmin)



from django.contrib import admin
from .models import Employee, InstagramApp
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from import_export.admin import ImportExportModelAdmin

# -- Instagram App Admin with Import/Export --
class InstagramAppAdmin(ImportExportModelAdmin):
    list_display = ('name', 'app_id')
    search_fields = ('name', 'app_id')


# -- Custom Employee Admin --
class EmployeeAdmin(BaseUserAdmin):
    model = Employee
    list_display = ('employee_id', 'name', 'is_staff', 'is_active')
    list_filter = ('is_staff', 'is_superuser', 'is_active')
    search_fields = ('employee_id', 'name')
    ordering = ('employee_id',)

    fieldsets = (
        (None, {'fields': ('employee_id', 'password')}),
        ('Personal Info', {'fields': ('name',)}),
        ('Assigned Apps', {'fields': ('instagram_apps',)}),
        ('Permissions', {
            'fields': ('is_staff', 'is_superuser', 'is_active', 'groups', 'user_permissions'),
        }),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'employee_id', 'name', 'password1', 'password2',
                'is_staff', 'is_superuser', 'is_active', 'instagram_apps',
            ),
        }),
    )

    filter_horizontal = ('instagram_apps', 'groups', 'user_permissions')


# -- Register Models in Admin --
admin.site.register(Employee, EmployeeAdmin)
admin.site.register(InstagramApp, InstagramAppAdmin)
