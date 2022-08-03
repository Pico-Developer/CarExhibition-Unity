using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit.Inputs;


/// <summary>
/// Provide the free movement
/// </summary>
public class FreeMoveProvider : LocomotionProvider
{
    [SerializeField] private float moveSpeed = 1f;
    [SerializeField] private float turnSpeed = 60f;

    [SerializeField] private InputActionProperty moveAction;

    [SerializeField] private InputActionProperty verticalMoveAction;

    private void Update()
    {
        var moveDirection = ReadMoveDirection();

        var moveDirection3 = new Vector3(moveDirection.x, 0, moveDirection.y);

        // var isUp = ReadUpAction();
        // var isDown = ReadDownAction();
        //
        //
        // var verticalDirection = new Vector3(0, (isUp ? 1 : 0) + (isDown ? -1 : 0), 0);

        var verticalDirection = new Vector3(0, ReadVerticalMoveDirection(), 0);

        if (CanBeginLocomotion() && BeginLocomotion())
        {
            var xrOrigin = system.xrOrigin;
            if (xrOrigin != null)
            {
                xrOrigin.RotateAroundCameraUsingOriginUp(ReadTurnDirection() * turnSpeed * Time.deltaTime);
            }

            // Actually Transform Move
            xrOrigin.transform.Translate((moveDirection3 + verticalDirection) * moveSpeed * Time.deltaTime, Space.Self);

            EndLocomotion();
        }
    }

    private Vector2 ReadMoveDirection()
    {
        var moveDirection = moveAction.action?.ReadValue<Vector2>() ?? Vector2.zero;

        return moveDirection;
    }

    private float ReadVerticalMoveDirection()
    {
        var verticalMoveDirection = verticalMoveAction.action?.ReadValue<Vector2>() ?? Vector2.zero;
        Debug.Log(verticalMoveAction);
        if (verticalMoveDirection == Vector2.zero) return 0f;
        var direction = CardinalUtility.GetNearestCardinal(verticalMoveDirection);

        if (direction == Cardinal.North || direction == Cardinal.South)
        {
            return verticalMoveDirection.magnitude * Mathf.Sign(verticalMoveDirection.y);
        }

        ;
        return 0f;
    }

    private float ReadTurnDirection()
    {
        var turnDirection = verticalMoveAction.action?.ReadValue<Vector2>() ?? Vector2.zero;

        if (turnDirection == Vector2.zero) return 0f;
        var direction = CardinalUtility.GetNearestCardinal(turnDirection);

        if (direction == Cardinal.East || direction == Cardinal.West)
        {
            return turnDirection.magnitude * Mathf.Sign(turnDirection.x);
        }

        ;
        return 0f;
    }


    private void OnEnable()
    {
        moveAction.EnableDirectAction();
        verticalMoveAction.EnableDirectAction();
    }

    private void OnDisable()
    {
        moveAction.DisableDirectAction();
        verticalMoveAction.DisableDirectAction();
    }
}